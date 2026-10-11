import Foundation

public extension TimetableLesson {
    /// Start/end on the lesson's calendar day, or nil if times are missing.
    func intervalOnLessonDay(calendar: Calendar = .current) -> (start: Date, end: Date)? {
        guard let fromTime, let untilTime else { return nil }
        let day = String(date.prefix(10))
        guard let start = Self.combined(day: day, time: fromTime),
              let end = Self.combined(day: day, time: untilTime),
              end > start else {
            return nil
        }
        return (start, end)
    }

    var durationMinutes: Int {
        guard let interval = intervalOnLessonDay() else { return 50 }
        return max(5, Int(interval.end.timeIntervalSince(interval.start) / 60))
    }

    var displayTimeRange: String? {
        guard let fromTime, let untilTime else { return nil }
        return "\(Self.shortTime(fromTime)) – \(Self.shortTime(untilTime))"
    }

    private static func combined(day: String, time: String) -> Date? {
        let timePart = String(time.prefix(8))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        return formatter.date(from: "\(day) \(timePart)")
    }

    private static func shortTime(_ raw: String) -> String {
        let part = String(raw.prefix(5))
        if part.count >= 5 { return part }
        return raw
    }
}
