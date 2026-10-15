import CoreDesign
import Domain
import SwiftUI

public struct LearnAssessmentDetailView: View {
    @State private var viewModel: LearnAssessmentDetailViewModel
    @State private var scrollOffsetY: CGFloat = 0
    @State private var showDescription = false
    @State private var showExpectations = false
    @State private var showCriteria = false

    public init(viewModel: LearnAssessmentDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
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
                    detailContent(detail)
                }
            }
            .padding(16)
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
    private func detailContent(_ detail: AssessmentDetail) -> some View {
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
                    Text(detail.displayStatus.rawValue)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(LearnTheme.Colors.card, in: Capsule())
                }
            }

            if detail.marked, detail.overallGrade != nil || detail.overallPercentage != nil {
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Results")
                            .font(.headline)
                        HStack(spacing: 16) {
                            if let grade = detail.overallGrade {
                                Text(grade)
                                    .font(.title.weight(.bold))
                            }
                            if let percent = detail.overallPercentage {
                                Text("\(percent)%")
                                    .font(.title3)
                            }
                        }
                        if let feedback = detail.feedbackComment {
                            Text(feedback)
                                .font(.body)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                        }
                    }
                }
            }

            LearnGlassCard {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Submission")
                        .font(.headline)
                    Text(detail.submitted ? "Submitted" : "Not submitted yet")
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
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

            if !detail.criteria.isEmpty {
                LearnGlassCard {
                    LearnProgressiveDisclosure(isExpanded: $showCriteria) {
                        Text("Criteria")
                            .font(.headline)
                            .foregroundStyle(LearnTheme.Colors.primaryText)
                    } content: {
                        ForEach(detail.criteria, id: \.name) { criterion in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(criterion.name)
                                    .font(.subheadline.weight(.semibold))
                                if let description = criterion.description {
                                    Text(description)
                                        .font(.caption)
                                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                                }
                                HStack {
                                    if let grade = criterion.grade {
                                        Text(grade)
                                    }
                                    if let percent = criterion.percentage {
                                        Text("\(percent)%")
                                    }
                                }
                                .font(.caption)
                            }
                            Divider()
                        }
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
