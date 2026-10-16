import Domain
import Foundation

/// DesQTA `gradeDisplay.ts` parity for assessment detail headers.
enum LearnAssessmentGradeDisplay {
    static func isNumericGradeString(_ value: String?) -> Bool {
        guard let value, !value.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return value.trimmingCharacters(in: .whitespaces).range(of: #"^\d+(\.\d+)?$"#, options: .regularExpression) != nil
    }

    static func formatDetailGrade(
        grade: String?,
        percentage: Int?,
        availableGrades: [String]
    ) -> String {
        let trimmedGrade = grade?.trimmingCharacters(in: .whitespaces) ?? ""

        if !trimmedGrade.isEmpty, isNumericGradeString(trimmedGrade) {
            if let value = Double(trimmedGrade) {
                return String(format: "%.2f%%", value)
            }
        }

        if trimmedGrade.isEmpty {
            if let percentage {
                return String(format: "%.2f%%", Double(percentage))
            }
            return "No Grade"
        }

        let scale = availableGrades
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        if !scale.isEmpty {
            let inList = scale.contains { $0.compare(trimmedGrade, options: .caseInsensitive) == .orderedSame }
            if inList {
                return trimmedGrade
            }
            if let percentage {
                return String(format: "%.2f%%", Double(percentage))
            }
            return trimmedGrade
        }

        return trimmedGrade
    }

    static func descriptorLabel(_ descriptor: AssessmentRubricDescriptor, index: Int) -> String {
        if let grade = descriptor.grade?.trimmingCharacters(in: .whitespaces), !grade.isEmpty {
            return grade
        }
        return String(index + 1)
    }
}
