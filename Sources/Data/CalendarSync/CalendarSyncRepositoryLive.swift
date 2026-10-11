import CoreCommon
import Domain
import EventKit
import Foundation

@MainActor
public final class CalendarSyncRepositoryLive: CalendarSyncRepository {
    private let studentRepository: StudentRepository
    private let eventStore = EKEventStore()
    private let preferencesStore = CalendarSyncPreferencesStore()

    private let syncHorizonDays = 28
    private let syncMarkerPrefix = "betterseqta-learn://calendar-sync/"

    public init(studentRepository: StudentRepository) {
        self.studentRepository = studentRepository
    }

    public func authorizationStatus() -> CalendarSyncAuthorizationStatus {
        mapAuthorization(EKEventStore.authorizationStatus(for: .event))
    }

    public func requestAccess() async -> CalendarSyncAuthorizationStatus {
        let granted: Bool
        if #available(iOS 17.0, *) {
            granted = (try? await eventStore.requestFullAccessToEvents()) ?? false
        } else {
            granted = await withCheckedContinuation { continuation in
                eventStore.requestAccess(to: .event) { allowed, _ in
                    continuation.resume(returning: allowed)
                }
            }
        }
        return granted ? .authorized : mapAuthorization(EKEventStore.authorizationStatus(for: .event))
    }

    public func loadPreferences() -> CalendarSyncPreferences {
        preferencesStore.loadPreferences()
    }

    public func savePreferences(_ preferences: CalendarSyncPreferences) {
        preferencesStore.savePreferences(preferences)
    }

    public func availableCalendars() -> [CalendarSyncCalendarOption] {
        eventStore.calendars(for: .event)
            .filter { $0.allowsContentModifications }
            .map { CalendarSyncCalendarOption(id: $0.calendarIdentifier, title: $0.title) }
            .sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
    }

    public func syncNow() async -> AppResult<CalendarSyncSummary> {
        var preferences = loadPreferences()
        guard preferences.isEnabled else {
            return .failure(.unknown(message: "Turn on calendar sync first."))
        }

        if authorizationStatus() != .authorized {
            let status = await requestAccess()
            guard status == .authorized else {
                return .failure(.unknown(message: "Calendar access was denied. Enable it in Settings."))
            }
        }

        guard let calendar = resolveCalendar(identifier: preferences.selectedCalendarIdentifier) else {
            return .failure(.unknown(message: "Choose a calendar to sync into."))
        }

        var timetableCount = 0
        var assessmentCount = 0

        if preferences.syncTimetable {
            switch await syncTimetable(into: calendar) {
            case .success(let count):
                timetableCount = count
            case .failure(let error):
                return .failure(error)
            }
        }

        if preferences.syncAssessments {
            switch await syncAssessments(into: calendar) {
            case .success(let count):
                assessmentCount = count
            case .failure(let error):
                return .failure(error)
            }
        }

        switch commitStore() {
        case .failure(let error):
            return .failure(error)
        case .success:
            break
        }

        let summary = CalendarSyncSummary(timetableEvents: timetableCount, assessmentEvents: assessmentCount)
        preferences.lastSyncedAt = Date()
        preferences.lastSyncSummary = summary.displayText
        savePreferences(preferences)
        return .success(summary)
    }

    public func removeSyncedEvents() async -> AppResult<Int> {
        if authorizationStatus() != .authorized {
            let status = await requestAccess()
            guard status == .authorized else {
                return .failure(.unknown(message: "Calendar access is required to remove synced events."))
            }
        }

        var removed = 0
        let timetableMap = preferencesStore.loadTimetableEventIDs()
        let assessmentMap = preferencesStore.loadAssessmentEventIDs()
        let trackedIDs = Set(timetableMap.values).union(assessmentMap.values)

        for eventID in trackedIDs {
            guard let event = eventStore.event(withIdentifier: eventID) else { continue }
            do {
                try eventStore.remove(event, span: .thisEvent, commit: false)
                removed += 1
            } catch {
                return .failure(.unknown(message: "Could not remove a synced calendar event."))
            }
        }

        let calendar = Calendar.current
        let scanStart = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        let scanEnd = calendar.date(byAdding: .year, value: 2, to: Date()) ?? Date()
        let predicate = eventStore.predicateForEvents(withStart: scanStart, end: scanEnd, calendars: nil)
        for event in eventStore.events(matching: predicate) {
            guard let notes = event.notes, notes.hasPrefix(syncMarkerPrefix) else { continue }
            guard let eventID = event.eventIdentifier, !trackedIDs.contains(eventID) else { continue }
            do {
                try eventStore.remove(event, span: .thisEvent, commit: false)
                removed += 1
            } catch {
                return .failure(.unknown(message: "Could not remove a synced calendar event."))
            }
        }

        preferencesStore.saveTimetableEventIDs([:])
        preferencesStore.saveAssessmentEventIDs([:])

        switch commitStore() {
        case .failure(let error):
            return .failure(error)
        case .success:
            var preferences = loadPreferences()
            preferences.lastSyncSummary = removed > 0
                ? "Removed \(removed) synced events from Calendar."
                : "No synced events were found to remove."
            savePreferences(preferences)
            return .success(removed)
        }
    }

    private func syncTimetable(into calendar: EKCalendar) async -> AppResult<Int> {
        let today = Calendar.current.startOfDay(for: Date())
        let fromDay = CalendarSyncDateParsing.isoDay(today)
        let untilDay = CalendarSyncDateParsing.isoDay(
            CalendarSyncDateParsing.date(byAddingDays: syncHorizonDays, to: today)
        )

        let result = await studentRepository.getTimetable(from: fromDay, until: untilDay)
        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let lessons):
            var eventMap: [String: String] = [:]
            for lesson in lessons {
                guard let interval = CalendarSyncDateParsing.lessonInterval(
                    date: lesson.date,
                    fromTime: lesson.fromTime,
                    untilTime: lesson.untilTime
                ) else { continue }

                let title = "\(lesson.subjectCode): \(lesson.title)"
                let notes = "\(syncMarkerPrefix)timetable/\(lesson.id)"
                switch saveEvent(
                    key: lesson.id,
                    existingMap: preferencesStore.loadTimetableEventIDs(),
                    title: title,
                    notes: notes,
                    location: lesson.room,
                    start: interval.start,
                    end: interval.end,
                    isAllDay: false,
                    calendar: calendar
                ) {
                case .success(let eventID):
                    eventMap[lesson.id] = eventID
                case .failure(let error):
                    return .failure(error)
                }
            }
            preferencesStore.saveTimetableEventIDs(eventMap)
            return .success(eventMap.count)
        }
    }

    private func syncAssessments(into calendar: EKCalendar) async -> AppResult<Int> {
        let result = await studentRepository.getUpcomingAssessments()
        switch result {
        case .failure(let error):
            return .failure(error)
        case .success(let assessments):
            var eventMap: [String: String] = [:]
            let existing = preferencesStore.loadAssessmentEventIDs()
            for assessment in assessments {
                guard let due = CalendarSyncDateParsing.assessmentDueDate(assessment.dueDate) else { continue }
                let key = String(assessment.id)
                let title = "Due: \(assessment.subjectCode) — \(assessment.title)"
                let notes = "\(syncMarkerPrefix)assessment/\(assessment.id)"
                switch saveEvent(
                    key: key,
                    existingMap: existing,
                    title: title,
                    notes: notes,
                    location: nil,
                    start: due,
                    end: due,
                    isAllDay: true,
                    calendar: calendar
                ) {
                case .success(let eventID):
                    eventMap[key] = eventID
                case .failure(let error):
                    return .failure(error)
                }
            }
            preferencesStore.saveAssessmentEventIDs(eventMap)
            return .success(eventMap.count)
        }
    }

    private func saveEvent(
        key: String,
        existingMap: [String: String],
        title: String,
        notes: String,
        location: String?,
        start: Date,
        end: Date,
        isAllDay: Bool,
        calendar: EKCalendar
    ) -> AppResult<String> {
        if let oldID = existingMap[key], let oldEvent = eventStore.event(withIdentifier: oldID) {
            do {
                try eventStore.remove(oldEvent, span: .thisEvent, commit: false)
            } catch {
                return .failure(.unknown(message: "Could not update an existing calendar event."))
            }
        }

        let event = EKEvent(eventStore: eventStore)
        event.calendar = calendar
        event.title = title
        event.notes = notes
        event.location = location
        event.isAllDay = isAllDay
        event.startDate = start
        event.endDate = isAllDay ? end : end
        if isAllDay {
            event.endDate = Calendar.current.date(byAdding: .day, value: 1, to: start) ?? start
        }

        do {
            try eventStore.save(event, span: .thisEvent, commit: false)
            return .success(event.eventIdentifier)
        } catch {
            return .failure(.unknown(message: "Could not save a calendar event."))
        }
    }

    private func resolveCalendar(identifier: String?) -> EKCalendar? {
        if let identifier,
           let calendar = eventStore.calendar(withIdentifier: identifier),
           calendar.allowsContentModifications {
            return calendar
        }
        return eventStore.defaultCalendarForNewEvents
    }

    private func mapAuthorization(_ status: EKAuthorizationStatus) -> CalendarSyncAuthorizationStatus {
        switch status {
        case .notDetermined:
            return .notDetermined
        case .restricted:
            return .restricted
        case .denied:
            return .denied
        case .authorized:
            return .authorized
        case .fullAccess:
            return .authorized
        case .writeOnly:
            return .denied
        @unknown default:
            return .denied
        }
    }

    private func commitStore() -> AppResult<Void> {
        do {
            try eventStore.commit()
            return .success(())
        } catch {
            return .failure(.unknown(message: "Could not save calendar changes."))
        }
    }
}
