import Foundation

/// Shared widget snapshot (mirrors Android `NextLessonSnapshot`).
public struct NextLessonWidgetSnapshot: Sendable, Codable, Equatable {
    public enum Kind: String, Codable, Sendable {
        case lesson
        case noLessons
        case signedOut
    }

    public var kind: Kind
    public var subjectName: String
    public var timeLabel: String?
    public var room: String?

    public init(kind: Kind, subjectName: String, timeLabel: String?, room: String?) {
        self.kind = kind
        self.subjectName = subjectName
        self.timeLabel = timeLabel
        self.room = room
    }

    public static let signedOut = NextLessonWidgetSnapshot(
        kind: .signedOut,
        subjectName: "Sign in required",
        timeLabel: "Open BetterSEQTA Learn",
        room: nil
    )

    public static let noLessons = NextLessonWidgetSnapshot(
        kind: .noLessons,
        subjectName: "No upcoming lessons",
        timeLabel: nil,
        room: nil
    )

    public var metaLine: String {
        let parts = [
            timeLabel?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
            room?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty.map { "Room \($0)" },
        ].compactMap { $0 }
        return parts.joined(separator: " · ")
    }
}

public enum NextLessonResolver {
    private static let isoDayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_AU_POSIX")
        formatter.timeZone = .current
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    public static func resolve(
        lessons: [TimetableLesson],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> NextLessonWidgetSnapshot {
        let sorted = lessons
            .filter { !$0.date.isEmpty && ($0.fromTime?.isEmpty == false) }
            .sorted { lhs, rhs in
                let left = lessonStart(lhs, calendar: calendar) ?? .distantFuture
                let right = lessonStart(rhs, calendar: calendar) ?? .distantFuture
                return left < right
            }

        guard let next = sorted.first(where: { lesson in
            guard let start = lessonStart(lesson, calendar: calendar) else { return false }
            return start > now
        }) else {
            return .noLessons
        }

        let lessonDate = isoDayFormatter.date(from: next.date) ?? now
        let dayStart = calendar.startOfDay(for: lessonDate)
        let todayStart = calendar.startOfDay(for: now)
        let dayLabel: String
        if dayStart == todayStart {
            dayLabel = "Today"
        } else if dayStart == calendar.date(byAdding: .day, value: 1, to: todayStart) {
            dayLabel = "Tomorrow"
        } else {
            dayLabel = lessonDate.formatted(.dateTime.weekday(.abbreviated))
        }

        let from = next.fromTime ?? ""
        let until = next.untilTime ?? ""
        let timeLabel = until.isEmpty ? "\(dayLabel), \(from)" : "\(dayLabel), \(from) – \(until)"
        let name = next.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            ? next.subjectCode
            : next.title
        let room = next.room?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty

        return NextLessonWidgetSnapshot(
            kind: .lesson,
            subjectName: name,
            timeLabel: timeLabel,
            room: room
        )
    }

    private static func lessonStart(_ lesson: TimetableLesson, calendar: Calendar) -> Date? {
        guard let from = lesson.fromTime?.trimmingCharacters(in: .whitespacesAndNewlines),
              !from.isEmpty,
              let day = isoDayFormatter.date(from: lesson.date) else { return nil }
        let parts = from.split(separator: ":")
        guard let hour = Int(parts.first ?? "") else { return nil }
        let minute = parts.count > 1 ? (Int(parts[1]) ?? 0) : 0
        var components = calendar.dateComponents([.year, .month, .day], from: day)
        components.hour = hour
        components.minute = minute
        components.second = 0
        return calendar.date(from: components)
    }
}

public enum LearnWidgetSharedStore {
    public static let appGroupIdentifier = "group.org.betterseqta.learn"
    private static let snapshotKey = "learn.widget.nextLesson"

    public static func save(_ snapshot: NextLessonWidgetSnapshot) {
        let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: snapshotKey)
    }

    public static func load() -> NextLessonWidgetSnapshot? {
        let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        guard let data = defaults.data(forKey: snapshotKey) else { return nil }
        return try? JSONDecoder().decode(NextLessonWidgetSnapshot.self, from: data)
    }

    public static func clear() {
        let defaults = UserDefaults(suiteName: appGroupIdentifier) ?? .standard
        defaults.removeObject(forKey: snapshotKey)
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
