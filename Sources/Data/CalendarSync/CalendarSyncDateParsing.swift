import Foundation

enum CalendarSyncDateParsing {
    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    static func lessonInterval(date: String, fromTime: String?, untilTime: String?) -> (start: Date, end: Date)? {
        guard let fromTime, let untilTime,
              let start = combined(date: date, time: fromTime),
              let end = combined(date: date, time: untilTime),
              end > start else {
            return nil
        }
        return (start, end)
    }

    static func assessmentDueDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        let normalized = String(raw.replacingOccurrences(of: " ", with: "T").prefix(10))
        return dayFormatter.date(from: normalized)
    }

    static func isoDay(_ date: Date) -> String {
        dayFormatter.string(from: date)
    }

    static func date(byAddingDays days: Int, to date: Date) -> Date {
        Calendar.current.date(byAdding: .day, value: days, to: date) ?? date
    }

    private static func combined(date: String, time: String) -> Date? {
        let day = String(date.prefix(10))
        let timePart = String(time.prefix(8))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: "\(day) \(timePart)")
    }
}
