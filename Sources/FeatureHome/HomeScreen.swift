import CoreDesign
import Domain
import FeatureNotices
import SwiftUI

public struct HomeScreen: View {
    @ObservedObject private var viewModel: HomeViewModel
    private let navigation: HomeNavigationCallbacks
    @State private var selectedNotice: Notice?
    @State private var scrollOffsetY: CGFloat = 0

    public init(viewModel: HomeViewModel, navigation: HomeNavigationCallbacks) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        let state = viewModel.uiState
        let subjectColours = subjectColourLookup(from: state.subjects)
        let filteredLessons = filteredLessons(from: state)
        let filteredAssessments = filteredAssessments(from: state)
        ScrollView {
            VStack(alignment: .leading, spacing: LearnTheme.Spacing.lg) {
                LearnScrollOffsetReporter()
                HomeDashboardHeader(displayName: state.displayName)

                HomeFilterMenus(
                    subjectsState: state.subjects,
                    selectedSubjectCode: state.selectedSubjectCode,
                    onSelectSubject: viewModel.selectSubjectFilter,
                    navigation: navigation
                )

                lessonsSection(lessons: filteredLessons, state: state, navigation: navigation)
                noticesSection(state: state, navigation: navigation)
                assessmentsSection(
                    state: state,
                    filtered: filteredAssessments,
                    subjectColours: subjectColours,
                    navigation: navigation
                )
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
            .padding(.bottom, 20)
            .learnReadableWidth()
        }
        .coordinateSpace(name: "learnScroll")
        .onPreferenceChange(LearnScrollOffsetKey.self) { scrollOffsetY = $0 }
        .learnScrollIslandChrome(
            title: "Home",
            progress: learnScrollProgress(from: scrollOffsetY)
        )
        .refreshable {
            viewModel.refresh()
        }
        .background { LearnScreenBackground() }
        .sheet(item: $selectedNotice) { notice in
            LearnNoticeDetailView(notice: notice)
        }
    }

    @ViewBuilder
    private func lessonsSection(
        lessons: [TimetableLesson],
        state: HomeUiState,
        navigation: HomeNavigationCallbacks
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(
                title: lessonSectionTitle(for: state.selectedDate),
                subtitle: lessonSectionSubtitle(for: state.selectedDate),
                actionLabel: "Timetable",
                onAction: navigation.onTimetableClick,
                trailing: {
                    AnyView(
                        HStack(spacing: 0) {
                            Button {
                                LearnHaptics.selection()
                                viewModel.selectPreviousDay()
                            } label: {
                                Image(systemName: "chevron.left")
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(LearnPressFeedbackStyle(scale: 0.9))
                            .accessibilityLabel("Previous day")
                            Button {
                                LearnHaptics.selection()
                                viewModel.selectNextDay()
                            } label: {
                                Image(systemName: "chevron.right")
                                    .frame(width: 32, height: 32)
                            }
                            .buttonStyle(LearnPressFeedbackStyle(scale: 0.9))
                            .accessibilityLabel("Next day")
                        }
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    )
                }
            )

            LearnDirectionalContent(
                identity: state.selectedDate,
                direction: state.dayNavigationDirection
            ) {
                groupedLessonsContent(lessons: lessons, state: state)
            }
            .animation(LearnMotion.spatialStandardDefault, value: state.selectedDate)
        }
    }

    @ViewBuilder
    private func groupedLessonsContent(lessons: [TimetableLesson], state: HomeUiState) -> some View {
        LearnGlassGroupedSection {
            switch state.lessons {
            case .loading:
                HomeSkeleton()
            case let .error(message):
                HomeSectionMessage(message: message)
            case .success:
                if lessons.isEmpty {
                    HomeSectionMessage(
                        message: state.selectedSubjectCode == nil
                            ? "No lessons scheduled"
                            : "No lessons for this subject",
                        secondary: "Change day or subject filter"
                    )
                } else {
                    ForEach(Array(lessons.prefix(4).enumerated()), id: \.element.id) { index, lesson in
                        if index > 0 { LearnGroupedDivider() }
                        HomeLessonCard(lesson: lesson)
                            .learnListEntrance(index: index)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func noticesSection(state: HomeUiState, navigation: HomeNavigationCallbacks) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(
                title: "Notices",
                subtitle: "Today at school",
                actionLabel: "All",
                onAction: navigation.onNoticesClick
            )

            LearnGlassGroupedSection {
                switch state.notices {
                case .loading:
                    HomeSkeleton()
                case let .error(message):
                    HomeSectionMessage(message: message)
                case let .success(notices):
                    if notices.isEmpty {
                        HomeSectionMessage(message: "No notices for today")
                    } else {
                        ForEach(Array(notices.prefix(3).enumerated()), id: \.element.id) { index, notice in
                            if index > 0 { LearnGroupedDivider() }
                            HomeNoticeCard(notice: notice) {
                                selectedNotice = notice
                            }
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func assessmentsSection(
        state: HomeUiState,
        filtered: [Assessment],
        subjectColours: [String: String?],
        navigation: HomeNavigationCallbacks
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            DashboardSectionHeader(
                title: "Tasks",
                subtitle: "Coming up",
                actionLabel: "All",
                onAction: navigation.onAssessmentsClick
            )

            LearnGlassGroupedSection {
                switch state.assessments {
                case .loading:
                    HomeSkeleton()
                case let .error(message):
                    HomeSectionMessage(message: message)
                case .success:
                    if filtered.isEmpty {
                        HomeSectionMessage(message: "No upcoming tasks")
                    } else {
                        ForEach(Array(filtered.prefix(4).enumerated()), id: \.element.id) { index, assessment in
                            if index > 0 { LearnGroupedDivider() }
                            HomeAssessmentCard(
                                assessment: assessment,
                                colour: HomeColourUtils.parseSubjectColour(
                                    subjectColours[assessment.subjectCode] ?? nil
                                ),
                                onTap: { navigation.onAssessmentClick(assessment) }
                            )
                        }
                    }
                }
            }
        }
    }

    private func subjectColourLookup(from state: SectionLoadState<[Subject]>) -> [String: String?] {
        guard case let .success(subjects) = state else { return [:] }
        // SEQTA may return multiple classes with the same subject code.
        return Dictionary(subjects.map { ($0.code, $0.colour) }, uniquingKeysWith: { first, next in
            first ?? next
        })
    }

    private func filteredLessons(from state: HomeUiState) -> [TimetableLesson] {
        guard case let .success(lessons) = state.lessons else { return [] }
        guard let filter = state.selectedSubjectCode else { return lessons }
        return lessons.filter { $0.subjectCode == filter }
    }

    private func filteredAssessments(from state: HomeUiState) -> [Assessment] {
        guard case let .success(assessments) = state.assessments else { return [] }
        guard let filter = state.selectedSubjectCode else { return assessments }
        return assessments.filter { $0.subjectCode == filter }
    }
}
