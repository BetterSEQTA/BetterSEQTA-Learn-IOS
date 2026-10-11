import XCTest

@testable import Data

final class AuthDeeplinkParserTests: XCTestCase {
    func testJwtValidatorRejectsExpired() {
        let expiredPayload = "eyJhbGciOiJIUzI1NiJ9.eyJleHAiOjEfQ.signature"
        XCTAssertNil(AuthJwtValidator.validate(token: expiredPayload))
    }

    func testParseSetCookie() {
        XCTAssertEqual(
            AuthURLHelpers.parseSetCookie("JSESSIONID=abc; Path=/seqta"),
            "abc"
        )
    }

    func testParseConnectDeeplinkReceivesSchoolUrlAndSession() {
        let json = #"{"u":"https://coneqt-s.jwacs.wa.edu.au","s":"RECEIVED_JSESSION_PLACEHOLDER"}"#
        let encoded = Data(json.utf8).base64EncodedString()
        let link = "desqta://connect/\(encoded)"
        let payload = AuthDeeplinkParser.parseConnectDeeplink(link)
        XCTAssertEqual(payload?.u, "https://coneqt-s.jwacs.wa.edu.au")
        XCTAssertEqual(payload?.s, "RECEIVED_JSESSION_PLACEHOLDER")
    }
}
