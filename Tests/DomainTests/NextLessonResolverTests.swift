import Domain
import XCTest

final class NextLessonResolverTests: XCTestCase {
    func testResolvePicksNextFutureLesson() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try makeDate(calendar: calendar, year: 2026, month: 4, day: 1, hour: 10, minute: 0)

        let lessons = [
            lesson(date: "2026-04-01", from: "09:00", until: "10:00", title: "Past"),
            lesson(date: "2026-04-01", from: "11:00", until: "12:00", title: "Maths", room: "B12"),
        ]

        let snapshot = NextLessonResolver.resolve(lessons: lessons, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.kind, .lesson)
        XCTAssertEqual(snapshot.subjectName, "Maths")
        XCTAssertEqual(snapshot.timeLabel, "Today, 11:00 – 12:00")
        XCTAssertEqual(snapshot.room, "B12")
    }

    func testResolveReturnsNoLessonsWhenNoneFuture() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let now = try makeDate(calendar: calendar, year: 2026, month: 4, day: 1, hour: 15, minute: 0)
        let lessons = [
            lesson(date: "2026-04-01", from: "09:00", until: "10:00", title: "Done"),
        ]
        let snapshot = NextLessonResolver.resolve(lessons: lessons, now: now, calendar: calendar)
        XCTAssertEqual(snapshot.kind, .noLessons)
    }

    private func lesson(
        date: String,
        from: String,
        until: String,
        title: String,
        room: String? = nil
    ) -> TimetableLesson {
        TimetableLesson(
            id: "\(date)-\(from)",
            date: date,
            fromTime: from,
            untilTime: until,
            subjectCode: "MAT",
            title: title,
            room: room,
            colour: nil
        )
    }

    private func makeDate(
        calendar: Calendar,
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int
    ) throws -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.hour = hour
        components.minute = minute
        components.second = 0
        guard let date = calendar.date(from: components) else {
            throw NSError(domain: "test", code: 1)
        }
        return date
    }
}
