import CoreDesign
import Domain
import SwiftUI

struct LearnAssessmentStatusChip: View {
    let status: AssessmentDisplayStatus

    var body: some View {
        Text(status.rawValue)
            .font(.caption2.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(chipColor.opacity(0.2), in: Capsule())
            .foregroundStyle(chipColor)
    }

    private var chipColor: Color {
        switch status {
        case .upcoming: LearnTheme.Colors.secondaryText
        case .dueSoon: .orange
        case .overdue: .red
        case .submitted: .blue
        case .marked: .green
        }
    }
}
