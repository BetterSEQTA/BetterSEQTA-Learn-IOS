import CoreDesign
import Domain
import SwiftUI

struct LearnAssessmentStatusChip: View {
    let status: AssessmentDisplayStatus

    var body: some View {
        LearnStatusChip(status.rawValue, tint: chipColor)
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
