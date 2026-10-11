import Domain
import Foundation

public struct HomeNavigationCallbacks: Sendable {
    public var onPortalsClick: @Sendable () -> Void
    public var onNoticesClick: @Sendable () -> Void
    public var onCoursesClick: @Sendable () -> Void
    public var onMessagesClick: @Sendable () -> Void
    public var onTimetableClick: @Sendable () -> Void
    public var onAssessmentsClick: @Sendable () -> Void
    public var onAssessmentClick: @Sendable (Assessment) -> Void

    public init(
        onPortalsClick: @escaping @Sendable () -> Void = {},
        onNoticesClick: @escaping @Sendable () -> Void = {},
        onCoursesClick: @escaping @Sendable () -> Void = {},
        onMessagesClick: @escaping @Sendable () -> Void = {},
        onTimetableClick: @escaping @Sendable () -> Void = {},
        onAssessmentsClick: @escaping @Sendable () -> Void = {},
        onAssessmentClick: @escaping @Sendable (Assessment) -> Void = { _ in }
    ) {
        self.onPortalsClick = onPortalsClick
        self.onNoticesClick = onNoticesClick
        self.onCoursesClick = onCoursesClick
        self.onMessagesClick = onMessagesClick
        self.onTimetableClick = onTimetableClick
        self.onAssessmentsClick = onAssessmentsClick
        self.onAssessmentClick = onAssessmentClick
    }
}

public enum SectionLoadState<T: Sendable>: Sendable, Equatable where T: Equatable {
    case loading
    case success(T)
    case error(String)

    public var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

public struct HomeUiState: Equatable, Sendable {
    public var selectedDate: Date
    public var subjects: SectionLoadState<[Subject]>
    public var lessons: SectionLoadState<[TimetableLesson]>
    public var assessments: SectionLoadState<[Assessment]>
    public var notices: SectionLoadState<[Notice]>
    public var selectedSubjectCode: String?
    public var isRefreshing: Bool
    public var isInitialLoad: Bool
    public var displayName: String?

    public init(
        selectedDate: Date = Calendar.current.startOfDay(for: Date()),
        subjects: SectionLoadState<[Subject]> = .loading,
        lessons: SectionLoadState<[TimetableLesson]> = .loading,
        assessments: SectionLoadState<[Assessment]> = .loading,
        notices: SectionLoadState<[Notice]> = .loading,
        selectedSubjectCode: String? = nil,
        isRefreshing: Bool = false,
        isInitialLoad: Bool = true,
        displayName: String? = nil
    ) {
        self.selectedDate = selectedDate
        self.subjects = subjects
        self.lessons = lessons
        self.assessments = assessments
        self.notices = notices
        self.selectedSubjectCode = selectedSubjectCode
        self.isRefreshing = isRefreshing
        self.isInitialLoad = isInitialLoad
        self.displayName = displayName
    }
}

@MainActor
public final class HomeLaunchGate: ObservableObject {
    @Published public private(set) var isHomeReady = false

    public init() {}

    public func markHomeReady() {
        if !isHomeReady {
            isHomeReady = true
        }
    }

    public func reset() {
        isHomeReady = false
    }
}
