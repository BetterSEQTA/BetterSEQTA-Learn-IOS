import Domain
import XCTest

final class SessionDataTests: XCTestCase {
    func testIsAuthenticatedRequiresBaseUrlAndCookie() {
        XCTAssertFalse(SessionData().isAuthenticated)
        XCTAssertFalse(SessionData(baseUrl: "https://school.example", jsessionId: "").isAuthenticated)
        XCTAssertTrue(
            SessionData(baseUrl: "https://school.example", jsessionId: "abc123").isAuthenticated
        )
    }

    func testClearedResetsSession() {
        let session = SessionData(baseUrl: "https://school.example", jsessionId: "abc", userId: 1)
        XCTAssertFalse(session.cleared().isAuthenticated)
    }
}
