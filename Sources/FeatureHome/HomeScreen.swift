import CoreDesign
import Domain
import SwiftUI

public struct HomeScreen: View {
    @ObservedObject private var viewModel: HomeViewModel
    private let navigation: HomeNavigationCallbacks

    public init(viewModel: HomeViewModel, navigation: HomeNavigationCallbacks) {
        self.viewModel = viewModel
        self.navigation = navigation
    }

    public var body: some View {
        let state = viewModel.uiState
        let subjectColours = subjectColourLookup(from: state.subjects)
        let filteredLessons = filteredLessons(from: state)
        let filteredAssessments = filteredAssessments(from: state)
        let showFluidLoader = state.isInitialLoad && (
            state.subjects.isLoading ||
                state.lessons.isLoading ||
                state.assessments.isLoading ||
                state.notices.isLoading
        )

        ScrollView {
            LazyVStack(spacing: 10) {
                HomeDashboardHeader(displayName: state.displayName)

                if showFluidLoader {
                    HomeFluidLoader(
                        progress: viewModel.loadProgress,
                        phaseText: viewModel.loadPhaseText
                    )
                }

                HomeShortcutsRow(navigation: navigation)
                    .opacity(state.isInitialLoad ? 0.6 : 1)

                if case .success = state.subjects {
                    HomeSubjectFilterRow(
                        subjectsState: state.subjects,
                        selectedSubjectCode: state.selectedSubjectCode,
                        onSelect: viewModel.selectSubjectFilter
                    )
                }

                lessonsSection(lessons: filteredLessons, state: state, navigation: navigation)
                noticesSection(state: state, navigation: navigation)
                assessmentsSection(
                    state: state,
                    filtered: filteredAssessments,
                    subjectColours: subjectColours,
                    navigation: navigation
                )
            }
            .padding(.bottom, 16)
        }
        .refreshable {
            viewModel.refresh()
        }
        .background(LearnTheme.Colors.background)
    }

    @ViewBuilder
    private func lessonsSection(
        lessons: [TimetableLesson],
        state: HomeUiState,
        navigation: HomeNavigationCallbacks
    ) -> some View {
        DashboardSectionHeader(
            title: lessonSectionTitle(for: state.selectedDate),
            subtitle: lessonSectionSubtitle(for: state.selectedDate),
            actionLabel: "See all",
            onAction: navigation.onTimetableClick,
            trailing: {
                AnyView(
                    HStack(spacing: 0) {
                        Button(action: viewModel.selectPreviousDay) {
                            Image(systemName: "chevron.left")
                        }
                        Button(action: viewModel.selectNextDay) {
                            Image(systemName: "chevron.right")
                        }
                    }
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                )
            }
        )

        switch state.lessons {
        case .loading:
            ForEach(0 ..< 3, id: \.self) { _ in
                widget { HomeSkeleton() }
            }
        case let .error(message):
            widget { HomeSectionMessage(message: message) }
        case .success:
            if lessons.isEmpty {
                widget {
                    HomeSectionMessage(
                        message: state.selectedSubjectCode == nil
                            ? "No lessons scheduled for this day"
                            : "No lessons for this subject today",
                        secondary: state.selectedSubjectCode == nil
                            ? "Use the arrows above or open Timetable for other days"
                            : "Clear the subject filter or pick another day"
                    )
                }
            } else {
                ForEach(lessons, id: \.id) { lesson in
                    widget { HomeLessonCard(lesson: lesson) }
                }
            }
        }
    }

    @ViewBuilder
    private func noticesSection(state: HomeUiState, navigation: HomeNavigationCallbacks) -> some View {
        DashboardSectionHeader(
            title: "Today's Notices",
            subtitle: "Announcements from your school",
            actionLabel: "See all",
            onAction: navigation.onNoticesClick
        )

        switch state.notices {
        case .loading:
            ForEach(0 ..< 2, id: \.self) { _ in
                widget { HomeSkeleton() }
            }
        case let .error(message):
            widget { HomeSectionMessage(message: message) }
        case let .success(notices):
            if notices.isEmpty {
                widget { HomeSectionMessage(message: "No notices for today") }
            } else {
                ForEach(Array(notices.prefix(3).enumerated()), id: \.offset) { _, notice in
                    widget {
                        HomeNoticeCard(notice: notice, onTap: navigation.onNoticesClick)
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
        DashboardSectionHeader(
            title: "Upcoming Assessments",
            subtitle: "Tasks due soon across your subjects",
            actionLabel: "See all",
            onAction: navigation.onAssessmentsClick
        )

        switch state.assessments {
        case .loading:
            ForEach(0 ..< 3, id: \.self) { _ in
                widget { HomeSkeleton() }
            }
        case let .error(message):
            widget { HomeSectionMessage(message: message) }
        case .success:
            if filtered.isEmpty {
                widget {
                    HomeSectionMessage(
                        message: state.selectedSubjectCode == nil
                            ? "No upcoming assessments"
                            : "No assessments for this subject",
                        secondary: state.selectedSubjectCode == nil
                            ? nil
                            : "Choose All or another subject filter"
                    )
                }
            } else {
                ForEach(Array(filtered.prefix(5)), id: \.id) { assessment in
                    widget {
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

    private func widget<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        LearnGlassCard {
            content()
        }
        .padding(.horizontal, 12)
    }

    private func subjectColourLookup(from state: SectionLoadState<[Subject]>) -> [String: String?] {
        guard case let .success(subjects) = state else { return [:] }
        return Dictionary(uniqueKeysWithValues: subjects.map { ($0.code, $0.colour) })
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
