import CoreDesign
import Domain
import Foundation
import Observation

public enum LearnTimetableDisplayMode: String, CaseIterable, Sendable {
    case agenda
    case day

    public var label: String {
        switch self {
        case .agenda: return "Agenda"
        case .day: return "Day"
        }
    }
}

public enum LearnLessonPhase: Sendable, Equatable {
    case past
    case current
    case upcoming
}

@MainActor
@Observable
public final class LearnTimetableViewModel {
    public var selectedDate = Calendar.current.startOfDay(for: Date())
    public var lessons: [TimetableLesson] = []
    public var dayNavigationDirection: LearnDayNavigationDirection = .forward
    public var displayMode: LearnTimetableDisplayMode = .agenda
    public var isLoading = false
    public var isRefreshing = false
    public var errorMessage: String?

    private let repository: StudentRepository
    private let calendar = Calendar.current
    nonisolated(unsafe) private var cacheListenerTask: Task<Void, Never>?

    public init(repository: StudentRepository) {
        self.repository = repository
        cacheListenerTask = StudentCacheUpdateListener.start(prefixes: ["timetable."]) { [weak self] in
            await self?.hydrateFromCache()
        }
    }

    deinit {
        cacheListenerTask?.cancel()
    }

    private func hydrateFromCache() async {
        let day = Self.isoDay(selectedDate)
        let key = StudentCacheKey.timetable(from: day, until: day).storageKey
        guard let cached: [TimetableLesson] = await repository.cachedValue(key) else { return }
        lessons = cached
            .filter { $0.date == day }
            .sorted { ($0.fromTime ?? "") < ($1.fromTime ?? "") }
    }

    public var isSelectedDateToday: Bool {
        calendar.isDateInToday(selectedDate)
    }

    public var weekDays: [Date] {
        weekDays(pageOffset: 0)
    }

    public func weekDays(pageOffset: Int) -> [Date] {
        let start = weekStart(containing: selectedDate)
        let anchor = calendar.date(byAdding: .weekOfYear, value: pageOffset, to: start) ?? start
        return Self.weekDays(containing: anchor, calendar: calendar)
    }

    public func shiftWeek(by weeks: Int) {
        guard weeks != 0 else { return }
        dayNavigationDirection = weeks > 0 ? .forward : .backward
        guard let shifted = calendar.date(byAdding: .weekOfYear, value: weeks, to: selectedDate) else { return }
        selectedDate = calendar.startOfDay(for: shifted)
        Task { await fetchDay() }
    }

    public var selectedDayISO: String {
        Self.isoDay(selectedDate)
    }

    /// Lesson in progress, or the next one today (for spotlight).
    public func spotlightLesson(now: Date = .now) -> TimetableLesson? {
        guard isSelectedDateToday else { return nil }
        if let live = lessons.first(where: { phase(for: $0, now: now) == .current }) {
            return live
        }
        return lessons.first(where: { phase(for: $0, now: now) == .upcoming })
    }

    public func phase(for lesson: TimetableLesson, now: Date = .now) -> LearnLessonPhase {
        let selectedStart = calendar.startOfDay(for: selectedDate)
        let todayStart = calendar.startOfDay(for: now)
        if selectedStart < todayStart { return .past }
        if selectedStart > todayStart { return .upcoming }
        guard let interval = lesson.intervalOnLessonDay(calendar: calendar) else { return .upcoming }
        if now >= interval.end { return .past }
        if now >= interval.start { return .current }
        return .upcoming
    }

    public func minutesUntilStart(of lesson: TimetableLesson, now: Date = .now) -> Int? {
        guard let start = lesson.intervalOnLessonDay(calendar: calendar)?.start else { return nil }
        let delta = start.timeIntervalSince(now)
        guard delta > 0 else { return nil }
        return max(1, Int(delta / 60))
    }

    public func load() async {
        guard !isLoading else { return }
        await hydrateFromCache()
        isLoading = lessons.isEmpty
        errorMessage = nil
        defer { isLoading = false }
        await fetchDay()
    }

    public func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }
        await fetchDay()
    }

    public func previousDay() {
        dayNavigationDirection = .backward
        selectedDate = calendar.date(byAdding: .day, value: -1, to: selectedDate) ?? selectedDate
        Task { await fetchDay() }
    }

    public func nextDay() {
        dayNavigationDirection = .forward
        selectedDate = calendar.date(byAdding: .day, value: 1, to: selectedDate) ?? selectedDate
        Task { await fetchDay() }
    }

    public func selectDate(_ date: Date) {
        let target = calendar.startOfDay(for: date)
        dayNavigationDirection = target > selectedDate ? .forward : .backward
        selectedDate = target
        Task { await fetchDay() }
    }

    public func goToToday() {
        selectDate(Date())
    }

    public func selectDisplayMode(_ mode: LearnTimetableDisplayMode) {
        displayMode = mode
    }

    private func fetchDay() async {
        let day = Self.isoDay(selectedDate)
        await hydrateFromCache()
        let result = await repository.getTimetable(from: day, until: day)
        switch result {
        case .success(let items):
            lessons = items
                .filter { $0.date == day }
                .sorted { lhs, rhs in
                    (lhs.fromTime ?? "") < (rhs.fromTime ?? "")
                }
            errorMessage = nil
        case .failure(let error):
            errorMessage = error.localizedDescription
            lessons = []
        }
    }

    private static func isoDay(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private func weekStart(containing date: Date) -> Date {
        calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
    }

    private static func weekDays(containing date: Date, calendar: Calendar) -> [Date] {
        let start = calendar.dateInterval(of: .weekOfYear, for: date)?.start
            ?? calendar.startOfDay(for: date)
        return (0 ..< 7).compactMap { offset in
            calendar.date(byAdding: .day, value: offset, to: start)
        }
    }
}
