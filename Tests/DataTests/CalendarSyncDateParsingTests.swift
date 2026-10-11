import XCTest
@testable import Data

final class CalendarSyncDateParsingTests: XCTestCase {
    func testLessonIntervalCombinesDateAndTime() {
        let interval = CalendarSyncDateParsing.lessonInterval(
            date: "2026-09-02",
            fromTime: "09:00:00",
            untilTime: "09:50:00"
        )
        XCTAssertNotNil(interval)
        XCTAssertTrue(interval!.end > interval!.start)
    }

    func testAssessmentDueDateParsesIsoDay() {
        XCTAssertNotNil(CalendarSyncDateParsing.assessmentDueDate("2026-09-02"))
        XCTAssertNotNil(CalendarSyncDateParsing.assessmentDueDate("2026-09-02 15:00:00"))
    }
}
