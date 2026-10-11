import Foundation

/// Parses SEQTA assessment due strings for scheduling (mirrors calendar sync parsing shapes).
public enum LearnAssessmentDueDate {
    public static func date(from raw: String?) -> Date? {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return nil
        }
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        let posix = Locale(identifier: "en_AU_POSIX")
        let formats = [
            "yyyy-MM-dd HH:mm:ss",
            "yyyy-MM-dd'T'HH:mm:ss",
            "yyyy-MM-dd",
        ]
        for pattern in formats {
            let formatter = DateFormatter()
            formatter.locale = posix
            formatter.timeZone = .current
            formatter.dateFormat = pattern
            if let date = formatter.date(from: trimmed) {
                return date
            }
        }
        return nil
    }
}
