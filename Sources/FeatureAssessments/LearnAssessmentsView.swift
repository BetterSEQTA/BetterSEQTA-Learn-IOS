import CoreDesign
import Domain
import SwiftUI

public struct LearnAssessmentsView: View {
    @State private var viewModel: LearnAssessmentsViewModel
    @State private var selectedAssessment: Assessment?

    public init(viewModel: LearnAssessmentsViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        assessmentsBody
            .learnShellNavigationDepth(0)
            .navigationDestination(item: $selectedAssessment) { assessment in
                LearnAssessmentDetailView(viewModel: viewModel.detailViewModel(for: assessment))
            }
    }

    private var assessmentsBody: some View {
        VStack(spacing: 0) {
            LearnUnderlineSegmentBar(
                items: LearnAssessmentsTab.allCases.map { ($0, $0.rawValue) },
                selection: viewModel.selectedTab,
                density: .compact,
                style: .fluid
            ) { tab in
                viewModel.selectedTab = tab
            }
            .padding(.horizontal, LearnLayout.horizontalPadding)
            .padding(.top, 4)
            .padding(.bottom, 2)

            Group {
                if viewModel.isLoading {
                    LearnLoadingState(preset: .assessmentList(rows: 6))
                        .animation(LearnMotion.spatialExpressiveFast, value: viewModel.isLoading)
                } else if let error = viewModel.errorMessage,
                          viewModel.upcoming.isEmpty,
                          viewModel.past.isEmpty {
                    LearnErrorBanner(message: error) {
                        Task { await viewModel.refresh() }
                    }
                } else if viewModel.selectedTab == .bySubject {
                    if viewModel.subjectGroups.isEmpty {
                        LearnEmptyState(
                            title: "No assessments",
                            message: "Assessments will appear grouped by subject when available."
                        )
                    } else {
                        List {
                            ForEach(viewModel.subjectGroups, id: \.subjectCode) { group in
                                Section(group.subjectCode) {
                                    ForEach(Array(group.items.enumerated()), id: \.element.id) { index, item in
                                        Button {
                                            LearnHaptics.lightImpact()
                                            selectedAssessment = item
                                        } label: {
                                            LearnAssessmentRow(assessment: item)
                                        }
                                        .learnRowPress()
                                        .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                        .listRowBackground(Color.clear)
                                        .learnListEntrance(index: index)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                        .refreshable { await viewModel.refresh() }
                    }
                } else if viewModel.visibleItems.isEmpty {
                    LearnEmptyState(
                        title: viewModel.selectedTab == .upcoming ? "No upcoming assessments" : "No past assessments",
                        message: viewModel.selectedTab == .upcoming
                            ? "You're all caught up for your active subjects."
                            : "Completed assessments will appear here once available."
                    )
                } else {
                    List {
                        ForEach(Array(viewModel.visibleItems.enumerated()), id: \.element.id) { index, item in
                            Button {
                                LearnHaptics.lightImpact()
                                selectedAssessment = item
                            } label: {
                                LearnAssessmentRow(assessment: item)
                            }
                            .learnRowPress()
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .listRowBackground(Color.clear)
                            .learnListEntrance(index: index)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.refresh() }
                }
            }
        }
        .background { LearnScreenBackground() }
        .task { await viewModel.load() }
        .onChange(of: viewModel.assessmentToOpen?.id) { _, _ in
            if let assessment = viewModel.consumeAssessmentToOpen() {
                selectedAssessment = assessment
            }
        }
    }
}

private struct LearnAssessmentRow: View {
    let assessment: Assessment

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            LearnListRow(
                accent: LearnSubjectColour.parse(assessment.subjectCode),
                title: assessment.title,
                subtitle: assessment.subjectCode,
                detail: assessment.dueDate.map { "Due \($0)" },
                footnote: assessment.grade
            )
            if assessment.grade == nil {
                LearnAssessmentStatusChip(status: assessment.listDisplayStatus())
            }
        }
        .padding(.vertical, 4)
    }
}

extension Assessment: Identifiable {}
