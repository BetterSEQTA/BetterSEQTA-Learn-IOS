import CoreDesign
import Domain
import SwiftUI

public struct LearnAssessmentDetailView: View {
    @State private var viewModel: LearnAssessmentDetailViewModel
    @Environment(\.dismiss) private var dismiss

    public init(viewModel: LearnAssessmentDetailViewModel) {
        _viewModel = State(initialValue: viewModel)
    }

    public var body: some View {
        ScrollView {
            Group {
                if viewModel.isLoading {
                    LearnLoadingState()
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
        .background(LearnTheme.Colors.background)
        .navigationTitle("Assessment")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Back") { dismiss() }
            }
        }
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
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                        Text(description)
                            .font(.body)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
            }

            if !detail.expectations.isEmpty {
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Expectations")
                            .font(.headline)
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
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Criteria")
                            .font(.headline)
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
}
