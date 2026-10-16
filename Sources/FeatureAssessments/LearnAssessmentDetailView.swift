import CoreDesign
import Domain
import SwiftUI

public struct LearnAssessmentDetailView: View {
    @State private var viewModel: LearnAssessmentDetailViewModel
    @State private var scrollOffsetY: CGFloat = 0
    @State private var showDescription = false
    @State private var showExpectations = false

    public init(viewModel: LearnAssessmentDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isLoading, viewModel.detail != nil {
                LearnUnderlineSegmentBar(
                    items: viewModel.visibleTabs.map { ($0, $0.rawValue) },
                    selection: viewModel.selectedTab,
                    density: .compact,
                    style: .fluid
                ) { tab in
                    viewModel.selectedTab = tab
                }
                .padding(.horizontal, LearnLayout.horizontalPadding)
                .padding(.top, 4)
                .padding(.bottom, 2)
            }

            ScrollView {
                Group {
                    LearnScrollOffsetReporter()
                    if viewModel.isLoading {
                        LearnLoadingState(preset: .detailBody)
                    } else if let error = viewModel.errorMessage {
                        LearnErrorBanner(message: error) {
                            Task { await viewModel.load() }
                        }
                    } else if let detail = viewModel.detail {
                        tabContent(detail)
                    }
                }
                .padding(16)
            }
        }
        .coordinateSpace(name: "learnScroll")
        .onPreferenceChange(LearnScrollOffsetKey.self) { scrollOffsetY = $0 }
        .learnScrollIslandChrome(
            title: viewModel.detail?.title ?? "Assessment",
            progress: learnScrollProgress(from: scrollOffsetY)
        )
        .background { LearnScreenBackground() }
        .navigationTitle(viewModel.detail?.title ?? "Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if let detail = viewModel.detail {
                ToolbarItem(placement: .topBarTrailing) {
                    LearnCopyMorphIconButton(
                        text: assessmentCopyText(detail),
                        accessibilityLabel: "Copy assessment details"
                    )
                }
            }
        }
        .learnShellNavigationDepth(1)
        .task { await viewModel.load() }
    }

    @ViewBuilder
    private func tabContent(_ detail: AssessmentDetail) -> some View {
        switch viewModel.selectedTab {
        case .overview:
            overviewContent(detail)
        case .details:
            LearnAssessmentCriteriaDetailsView(detail: detail)
        case .submissions:
            LearnAssessmentSubmissionsSection(
                files: detail.studentSubmissions,
                downloadingUUID: viewModel.downloadingSubmissionUUID,
                errorMessage: viewModel.submissionErrorMessage,
                onDownload: { file in
                    Task { await viewModel.downloadSubmission(file) }
                }
            )
        }
    }

    @ViewBuilder
    private func overviewContent(_ detail: AssessmentDetail) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            LearnGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text(detail.title)
                        .font(.title2.weight(.bold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    Text(detail.subjectTitle)
                        .font(.subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                    if let due = detail.dueDate {
                        Text(due)
                            .font(.subheadline)
                            .foregroundStyle(Color.accentColor)
                    }
                    LearnAssessmentStatusChip(status: detail.displayStatus)
                }
            }

            if detail.marked, detail.overallGrade != nil || detail.overallPercentage != nil {
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Results")
                            .font(.headline)
                        Text(
                            LearnAssessmentGradeDisplay.formatDetailGrade(
                                grade: detail.overallGrade,
                                percentage: detail.overallPercentage,
                                availableGrades: detail.availableGrades
                            )
                        )
                        .font(.title2.weight(.bold))
                    }
                }
            }

            LearnGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Submission")
                        .font(.headline)
                    if detail.fileSubmissionEnabled {
                        Text(detail.submitted ? "Files on record" : "Not submitted yet")
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                        if detail.submitted {
                            Button("View submissions") {
                                viewModel.selectedTab = .submissions
                            }
                            .font(.subheadline.weight(.semibold))
                        }
                    } else {
                        Text(detail.submitted ? "Submitted" : "Not submitted yet")
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
            }

            if let description = detail.description, !description.isEmpty {
                LearnGlassCard {
                    LearnProgressiveDisclosure(isExpanded: $showDescription) {
                        Text("Description")
                            .font(.headline)
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                    } content: {
                        Text(description)
                            .font(.body)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
            }

            if !detail.expectations.isEmpty {
                LearnGlassCard {
                    LearnProgressiveDisclosure(isExpanded: $showExpectations) {
                        Text("Expectations")
                            .font(.headline)
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                    } content: {
                        ForEach(detail.expectations, id: \.self) { item in
                            Text("• \(item)")
                                .font(.subheadline)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                        }
                    }
                }
            }

            if !detail.criteriaWithRubrics.isEmpty || detail.marked {
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Criteria & feedback")
                            .font(.headline)
                        Text("View rubric tables, grades, and teacher comments on the Details tab.")
                            .font(.subheadline)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                        Button("Open Details") {
                            viewModel.selectedTab = .details
                        }
                        .font(.subheadline.weight(.semibold))
                    }
                }
            }
        }
    }

    private func assessmentCopyText(_ detail: AssessmentDetail) -> String {
        var lines = [detail.title, detail.subjectTitle]
        if let due = detail.dueDate { lines.append("Due: \(due)") }
        lines.append("Status: \(detail.displayStatus.rawValue)")
        if let grade = detail.overallGrade { lines.append("Grade: \(grade)") }
        if let percent = detail.overallPercentage { lines.append("Mark: \(percent)%") }
        return lines.joined(separator: "\n")
    }
}
