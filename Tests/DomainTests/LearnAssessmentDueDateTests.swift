import Domain
import XCTest

final class LearnAssessmentDueDateTests: XCTestCase {
    func testParsesDateOnly() {
        XCTAssertNotNil(LearnAssessmentDueDate.date(from: "2026-09-02"))
    }

    func testParsesDateTime() {
        XCTAssertNotNil(LearnAssessmentDueDate.date(from: "2026-09-02 15:00:00"))
    }
}
