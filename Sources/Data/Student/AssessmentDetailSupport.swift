import Domain
import Foundation

enum AssessmentDetailSupport {
    static func resolveMetaclass(
        assessment: Assessment,
        metaclass: Int,
        subjects: [Subject]
    ) -> Int {
        if metaclass > 0 { return metaclass }
        if let match = subjects.first(where: { $0.code == assessment.subjectCode }),
           let value = match.metaclass {
            return value
        }
        if let match = subjects.first(where: { $0.code == assessment.subjectCode }) {
            return match.id
        }
        return 0
    }

    static func displayStatus(for assessment: Assessment, submitted: Bool) -> AssessmentDisplayStatus {
        if isMarksReleased(assessment) { return .marked }
        if submitted || assessment.status?.uppercased() == "SUBMITTED" { return .submitted }
        guard let due = parseDueDate(assessment.dueDate) else { return .upcoming }
        let today = Calendar.current.startOfDay(for: Date())
        let dueDay = Calendar.current.startOfDay(for: due)
        let days = Calendar.current.dateComponents([.day], from: today, to: dueDay).day ?? 0
        if days < 0 { return .overdue }
        if days <= 7 { return .dueSoon }
        return .upcoming
    }

    static func isMarksReleased(_ assessment: Assessment) -> Bool {
        let status = assessment.status?.uppercased() ?? ""
        if assessment.marked || assessment.grade != nil || assessment.percentage != nil { return true }
        if status == "MARKS_RELEASED" { return true }
        if status.contains("RELEASE") { return true }
        if status.contains("MARK"), !status.contains("REMARK") { return true }
        return false
    }

    private static func parseDueDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let normalized = raw.replacingOccurrences(of: " ", with: "T").prefix(10)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: String(normalized))
    }
}
