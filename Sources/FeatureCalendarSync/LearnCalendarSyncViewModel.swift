import CoreCommon
import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnCalendarSyncViewModel {
    public var preferences: CalendarSyncPreferences
    public var authorizationStatus: CalendarSyncAuthorizationStatus
    public var calendars: [CalendarSyncCalendarOption] = []
    public var isSyncing = false
    public var errorMessage: String?
    public var statusMessage: String?

    private let repository: CalendarSyncRepository

    public init(repository: CalendarSyncRepository) {
        self.repository = repository
        preferences = repository.loadPreferences()
        authorizationStatus = repository.authorizationStatus()
        refreshCalendars()
    }

    public func refresh() {
        preferences = repository.loadPreferences()
        authorizationStatus = repository.authorizationStatus()
        refreshCalendars()
    }

    public func setEnabled(_ enabled: Bool) {
        preferences.isEnabled = enabled
        if !enabled {
            preferences.autoSyncEnabled = false
        }
        repository.savePreferences(preferences)
        LearnCalendarSyncBackground.scheduleAutoSync(
            enabled: preferences.isEnabled && preferences.autoSyncEnabled
        )
        if enabled {
            Task { await syncNow() }
        }
    }

    public func setAutoSyncEnabled(_ enabled: Bool) {
        preferences.autoSyncEnabled = enabled
        repository.savePreferences(preferences)
        LearnCalendarSyncBackground.scheduleAutoSync(
            enabled: preferences.isEnabled && preferences.autoSyncEnabled
        )
    }

    public func setSyncTimetable(_ enabled: Bool) {
        preferences.syncTimetable = enabled
        repository.savePreferences(preferences)
    }

    public func setSyncAssessments(_ enabled: Bool) {
        preferences.syncAssessments = enabled
        repository.savePreferences(preferences)
    }

    public func selectCalendar(id: String?) {
        preferences.selectedCalendarIdentifier = id
        repository.savePreferences(preferences)
    }

    public func requestAccess() async {
        authorizationStatus = await repository.requestAccess()
        refreshCalendars()
    }

    public func syncNow() async {
        guard !isSyncing else { return }
        isSyncing = true
        errorMessage = nil
        statusMessage = nil
        defer { isSyncing = false }

        if authorizationStatus == .notDetermined {
            authorizationStatus = await repository.requestAccess()
        }
        guard authorizationStatus == .authorized else {
            errorMessage = "Calendar access is required to sync lessons and assessments."
            return
        }

        preferences.isEnabled = true
        repository.savePreferences(preferences)

        let result = await repository.syncNow()
        preferences = repository.loadPreferences()
        switch result {
        case .success(let summary):
            statusMessage = summary.displayText
            errorMessage = nil
        case .failure(let error):
            errorMessage = localized(error)
        }
    }

    private func refreshCalendars() {
        guard authorizationStatus == .authorized else {
            calendars = []
            return
        }
        calendars = repository.availableCalendars()
        if preferences.selectedCalendarIdentifier == nil, let first = calendars.first {
            preferences.selectedCalendarIdentifier = first.id
            repository.savePreferences(preferences)
        }
    }

    private func localized(_ error: AppError) -> String {
        switch error {
        case let .auth(message): message
        case let .network(message): message
        case .sessionExpired: "Session expired"
        case let .unknown(message): message
        }
    }
}
