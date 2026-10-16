import CoreDesign
import Domain
import SwiftUI

/// Rubric / criteria tables (DesQTA `AssessmentDetails.svelte`).
struct LearnAssessmentCriteriaDetailsView: View {
    let detail: AssessmentDetail

    private var firstCriterion: AssessmentCriterion? {
        detail.criteria.first
    }

    private var gradeBarPercent: Double {
        guard let percent = firstCriterion?.percentage ?? detail.overallPercentage else { return 0 }
        return min(100, max(0, Double(percent)))
    }

    private var gradeScale: [String] {
        if let first = firstCriterion?.availableGrades, !first.isEmpty {
            return first
        }
        return detail.availableGrades
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if detail.marked {
                gradeCard
            }

            if detail.criteriaWithRubrics.isEmpty, !detail.marked {
                LearnEmptyState(
                    title: "No rubric yet",
                    message: "Criteria tables appear here once your teacher publishes rubrics or marks."
                )
            } else {
                ForEach(detail.criteriaWithRubrics, id: \.name) { criterion in
                    criterionRubricCard(criterion)
                }
            }

            if detail.marked, let feedback = detail.feedbackComment, !feedback.isEmpty {
                LearnGlassCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Teacher feedback")
                            .font(.headline)
                        Text(feedback)
                            .font(.body)
                            .foregroundStyle(LearnTheme.Colors.secondaryText)
                    }
                }
            }
        }
    }

    private var gradeCard: some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 10) {
                Text("Grade")
                    .font(.headline)
                if let criterion = firstCriterion, criterion.grade != nil || criterion.percentage != nil {
                    Text(
                        LearnAssessmentGradeDisplay.formatDetailGrade(
                            grade: criterion.grade,
                            percentage: criterion.percentage,
                            availableGrades: gradeScale
                        )
                    )
                    .font(.title.weight(.bold))
                    GeometryReader { proxy in
                        ZStack(alignment: .leading) {
                            Capsule()
                                .fill(LearnTheme.Colors.card)
                            Capsule()
                                .fill(LearnTheme.Colors.accent)
                                .frame(width: proxy.size.width * gradeBarPercent / 100)
                        }
                    }
                    .frame(height: 8)
                } else {
                    Text("No grade released yet")
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                }
            }
        }
    }

    private func criterionRubricCard(_ criterion: AssessmentCriterion) -> some View {
        LearnGlassCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(criterion.name)
                    .font(.headline)

                if let rubric = criterion.rubric {
                    ForEach(rubric.activeLines) { line in
                        rubricLineBlock(criterion: criterion, line: line)
                    }
                }
            }
        }
    }

    private func rubricLineBlock(criterion: AssessmentCriterion, line: AssessmentRubricLine) -> some View {
        let lineScore = criterion.rubricScores[String(line.id)]
        return VStack(alignment: .leading, spacing: 8) {
            if let title = line.title, !title.isEmpty {
                Text(title)
                    .font(.subheadline.weight(.semibold))
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 8) {
                    ForEach(Array(line.descriptors.enumerated()), id: \.element.id) { index, descriptor in
                        let selected = lineScore?.descriptorId == descriptor.id
                        let label = LearnAssessmentGradeDisplay.descriptorLabel(descriptor, index: index)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 4) {
                                Text(label)
                                    .font(.caption.weight(.bold))
                                if selected,
                                   let scoreGrade = lineScore?.grade,
                                   !scoreGrade.trimmingCharacters(in: .whitespaces).isEmpty,
                                   scoreGrade != label
                                {
                                    Text(scoreGrade)
                                        .font(.caption2)
                                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                                }
                            }
                            Text(descriptor.content ?? "")
                                .font(.caption)
                                .foregroundStyle(LearnTheme.Colors.secondaryText)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .frame(width: 148, alignment: .topLeading)
                        .padding(10)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(selected ? LearnTheme.Colors.accent.opacity(0.18) : LearnTheme.Colors.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .strokeBorder(selected ? LearnTheme.Colors.accent : Color.clear, lineWidth: 2)
                        )
                    }
                }
            }
        }
    }
}
