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
        NavigationStack {
            assessmentsBody
                .navigationDestination(item: $selectedAssessment) { assessment in
                    LearnAssessmentDetailView(viewModel: viewModel.detailViewModel(for: assessment))
                }
        }
    }

    private var assessmentsBody: some View {
        VStack(spacing: 0) {
            LearnScreenHeader(
                title: "Assessments",
                subtitle: "View upcoming and past tasks"
            )

            Picker("Tab", selection: $viewModel.selectedTab) {
                ForEach(LearnAssessmentsTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)

            Group {
                if viewModel.isLoading {
                    LearnLoadingState()
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
                                    ForEach(group.items) { item in
                                        Button {
                                            selectedAssessment = item
                                        } label: {
                                            LearnAssessmentRow(assessment: item)
                                        }
                                        .buttonStyle(.plain)
                                        .listRowBackground(Color.clear)
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
                    List(viewModel.visibleItems) { item in
                        Button {
                            selectedAssessment = item
                        } label: {
                            LearnAssessmentRow(assessment: item)
                        }
                        .buttonStyle(.plain)
                        .listRowBackground(Color.clear)
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .refreshable { await viewModel.refresh() }
                }
            }
        }
        .background(LearnTheme.Colors.background)
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
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(assessment.subjectCode)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    Spacer()
                    if let grade = assessment.grade {
                        Text(grade)
                            .font(.caption.weight(.bold))
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                    } else {
                        LearnAssessmentStatusChip(status: assessment.listDisplayStatus())
                    }
                }
                Text(assessment.title)
                    .font(.headline)
                    .foregroundStyle(LearnTheme.Colors.primaryText)
                if let due = assessment.dueDate {
                    Text(due)
                        .font(.caption)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
        }
    }
}

extension Assessment: Identifiable {}
