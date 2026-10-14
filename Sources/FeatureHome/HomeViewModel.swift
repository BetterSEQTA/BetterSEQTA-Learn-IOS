import CoreCommon
import CoreDesign
import Domain
import FeatureNotifications
import Foundation

@MainActor
public final class HomeViewModel: ObservableObject {
    @Published public private(set) var uiState = HomeUiState()
    @Published public private(set) var loadProgress: Float = 0
    @Published public private(set) var loadPhaseText = "Warming up…"

    private let studentRepository: StudentRepository
    private let launchGate: HomeLaunchGate
    nonisolated(unsafe) private var cacheListenerTask: Task<Void, Never>?
    private var sectionsCompletedThisRefresh = 0
    private var sectionsTotalThisRefresh = 4
    private let isoDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public init(studentRepository: StudentRepository, launchGate: HomeLaunchGate) {
        self.studentRepository = studentRepository
        self.launchGate = launchGate
        cacheListenerTask = StudentCacheUpdateListener.start(
            prefixes: ["subjects", "timetable.", "assessments.", "notices.", "profile"]
        ) { [weak self] in
            await self?.applyCacheToHomeState()
        }
        refresh(includeWarmup: true)
    }

    deinit {
        cacheListenerTask?.cancel()
    }

    private func applyCacheToHomeState() async {
        let isoDate = isoDayFormatter.string(from: uiState.selectedDate)
        if let profile: UserProfile = await studentRepository.cachedValue(StudentCacheKey.profile.storageKey) {
            let trimmed = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            uiState.displayName = trimmed.isEmpty ? profile.userName : trimmed
        }
        if let subjects: [Subject] = await studentRepository.cachedValue(StudentCacheKey.subjects.storageKey) {
            uiState.subjects = .success(subjects)
        }
        let timetableKey = StudentCacheKey.timetable(from: isoDate, until: isoDate).storageKey
        if let lessons: [TimetableLesson] = await studentRepository.cachedValue(timetableKey) {
            uiState.lessons = .success(Self.sortedLessons(lessons.filter { $0.date == isoDate }))
        }
        if let assessments: [Assessment] = await studentRepository.cachedValue(
            StudentCacheKey.assessmentsUpcoming.storageKey
        ) {
            let subjectCodes: [String]
            if case let .success(subjects) = uiState.subjects {
                subjectCodes = subjects.map(\.code)
            } else {
                subjectCodes = []
            }
            uiState.assessments = .success(
                assessments
                    .filter { subjectCodes.isEmpty || subjectCodes.contains($0.subjectCode) }
                    .sorted { ($0.dueDate ?? "") < ($1.dueDate ?? "") }
            )
        }
        let noticesKey = StudentCacheKey.notices(date: isoDate).storageKey
        if let notices: [Notice] = await studentRepository.cachedValue(noticesKey) {
            uiState.notices = .success(notices)
        }
    }

    public func refresh(includeWarmup: Bool = false) {
        Task {
            await performRefresh(includeWarmup: includeWarmup)
        }
    }

    public func selectPreviousDay() {
        let calendar = Calendar.current
        uiState.dayNavigationDirection = .backward
        uiState.selectedDate = calendar.date(byAdding: .day, value: -1, to: uiState.selectedDate)
            ?? uiState.selectedDate
        reloadLessons()
    }

    public func selectNextDay() {
        let calendar = Calendar.current
        uiState.dayNavigationDirection = .forward
        uiState.selectedDate = calendar.date(byAdding: .day, value: 1, to: uiState.selectedDate)
            ?? uiState.selectedDate
        reloadLessons()
    }

    public func selectSubjectFilter(_ subjectCode: String?) {
        if uiState.selectedSubjectCode == subjectCode {
            uiState.selectedSubjectCode = nil
        } else {
            uiState.selectedSubjectCode = subjectCode
        }
    }

    private func reloadLessons() {
        Task {
            let date = uiState.selectedDate
            let isoDate = isoDayFormatter.string(from: date)
            let timetableKey = StudentCacheKey.timetable(from: isoDate, until: isoDate).storageKey
            if let cached: [TimetableLesson] = await studentRepository.cachedValue(timetableKey) {
                uiState.lessons = .success(Self.sortedLessons(cached.filter { $0.date == isoDate }))
            } else {
                uiState.lessons = .loading
            }
            let result = await studentRepository.getTimetable(from: isoDate, until: isoDate)
            uiState.lessons = result.toSectionState([]) { lessons in
                Self.sortedLessons(lessons.filter { $0.date == isoDate })
            }
        }
    }

    private func performRefresh(includeWarmup: Bool) async {
        let date = uiState.selectedDate
        let isoDate = isoDayFormatter.string(from: date)
        let isPullRefresh = !uiState.isInitialLoad && !includeWarmup

        await applyCacheToHomeState()

        uiState.isRefreshing = isPullRefresh
        if !isPullRefresh {
            uiState.subjects = .loading
            uiState.assessments = .loading
            uiState.notices = .loading
        }
        uiState.lessons = .loading

        loadProgress = 0.06
        loadPhaseText = "Loading home…"
        sectionsCompletedThisRefresh = 0
        sectionsTotalThisRefresh = includeWarmup ? 5 : 4

        async let warmup: Void = performWarmupIfNeeded(includeWarmup)

        async let subjectsResult = fetchSubjects()
        async let lessonsResult = fetchLessons(isoDate: isoDate)
        async let assessmentsResult = fetchAssessments()
        async let noticesResult = fetchNotices(isoDate: isoDate)
        async let profileResult = studentRepository.getProfile()

        let subjects = await subjectsResult
        let lessons = await lessonsResult

        if includeWarmup {
            uiState.subjects = subjects.toSectionState([]) { $0 }
            uiState.lessons = lessons.toSectionState([]) { items in
                Self.sortedLessons(items.filter { $0.date == isoDate })
            }
            loadProgress = 0.55
            loadPhaseText = "Almost ready…"
            launchGate.markHomeReady()
        }

        await warmup
        let assessments = await assessmentsResult
        let notices = await noticesResult
        let subjectCodes = subjects.value?.map(\.code) ?? []
        let assessmentItems = assessments.value ?? []
        let noticeItems = notices.value ?? []
        if case let .success(profile) = await profileResult {
            let trimmed = profile.displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            uiState.displayName = trimmed.isEmpty ? profile.userName : trimmed
        }

        uiState.subjects = subjects.toSectionState([]) { $0 }
        uiState.lessons = lessons.toSectionState([]) { items in
            Self.sortedLessons(items.filter { $0.date == isoDate })
        }
        uiState.assessments = assessments.toSectionState([]) { items in
            items
                .filter { subjectCodes.contains($0.subjectCode) }
                .sorted { ($0.dueDate ?? "") < ($1.dueDate ?? "") }
        }
        uiState.notices = notices.toSectionState([]) { $0 }
        uiState.isRefreshing = false
        uiState.isInitialLoad = false
        loadProgress = 1
        loadPhaseText = "Home ready"

        if includeWarmup && !launchGate.isHomeReady {
            launchGate.markHomeReady()
        }

        Task { await refreshWidgetSnapshot() }
        Task { @MainActor in
            let prefs = LearnNotificationPreferencesStore()
            await LearnLocalNotificationPlanner.syncAfterHomeLoad(
                assessments: assessmentItems.filter { subjectCodes.contains($0.subjectCode) },
                notices: noticeItems,
                assessmentRemindersEnabled: prefs.assessmentRemindersEnabled,
                noticeAlertsEnabled: prefs.noticeAlertsEnabled
            )
        }
    }

    private static func sortedLessons(_ lessons: [TimetableLesson]) -> [TimetableLesson] {
        lessons.sorted { ($0.fromTime ?? "") < ($1.fromTime ?? "") }
    }

    private func refreshWidgetSnapshot() async {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let until = calendar.date(byAdding: .day, value: 14, to: today) ?? today
        let fromISO = isoDayFormatter.string(from: today)
        let untilISO = isoDayFormatter.string(from: until)
        switch await studentRepository.getTimetable(from: fromISO, until: untilISO) {
        case let .success(lessons):
            HomeWidgetRefresh.publish(lessons: lessons)
        case .failure:
            break
        }
    }

    private func completeLoadSection(_ phase: String) {
        sectionsCompletedThisRefresh += 1
        loadProgress = min(1, Float(sectionsCompletedThisRefresh) / Float(sectionsTotalThisRefresh))
        loadPhaseText = phase
    }

    private func performWarmupIfNeeded(_ includeWarmup: Bool) async {
        guard includeWarmup else { return }
        _ = await studentRepository.sendHeartbeat()
        completeLoadSection("Connected")
    }

    private func fetchSubjects() async -> AppResult<[Subject]> {
        let result = await studentRepository.getSubjects()
        completeLoadSection(result.phaseLabel(success: "Subjects ready", failure: "Subjects unavailable"))
        return result
    }

    private func fetchLessons(isoDate: String) async -> AppResult<[TimetableLesson]> {
        let result = await studentRepository.getTimetable(from: isoDate, until: isoDate)
        completeLoadSection(result.phaseLabel(success: "Timetable ready", failure: "Timetable unavailable"))
        return result
    }

    private func fetchAssessments() async -> AppResult<[Assessment]> {
        let result = await studentRepository.getUpcomingAssessments()
        completeLoadSection(result.phaseLabel(success: "Assessments ready", failure: "Assessments unavailable"))
        return result
    }

    private func fetchNotices(isoDate: String) async -> AppResult<[Notice]> {
        let result = await studentRepository.getNotices(date: isoDate)
        completeLoadSection(result.phaseLabel(success: "Notices ready", failure: "Notices unavailable"))
        return result
    }
}

private extension AppResult {
    func toSectionState<R: Equatable & Sendable>(
        _ fallback: R,
        transform: (T) -> R
    ) -> SectionLoadState<R> {
        switch self {
        case let .success(value):
            return .success(transform(value))
        case let .failure(error):
            return .error(error.homeMessage)
        }
    }

    func phaseLabel(success: String, failure: String) -> String {
        switch self {
        case .success:
            return success
        case .failure:
            return failure
        }
    }
}

private extension AppError {
    var homeMessage: String {
        switch self {
        case let .auth(message):
            return message
        case let .network(message):
            return message.friendlyHomeError
        case .sessionExpired:
            return "Session expired"
        case let .unknown(message):
            return message.friendlyHomeError
        }
    }
}

private extension String {
    var friendlyHomeError: String {
        if contains("Fields [") || contains("Expected JsonObject") || contains("serial name") {
            return "Couldn't load this section. Pull to refresh."
        }
        if count > 120 {
            return String(prefix(117)) + "…"
        }
        return self
    }
}
