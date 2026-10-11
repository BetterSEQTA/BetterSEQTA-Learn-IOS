import FeatureAuth
import XCTest

final class WebSessionCookieParserTests: XCTestCase {
    func testParseJsessionId() {
        XCTAssertEqual(
            WebSessionCookieParser.parseJsessionId(cookieHeader: "JSESSIONID=abc123; Path=/"),
            "abc123"
        )
    }

    func testNormalizeSchoolBaseUrl() {
        XCTAssertEqual(
            WebSessionCookieParser.normalizeSchoolBaseUrl("school.seqta.com.au"),
            "https://school.seqta.com.au"
        )
    }

    func testLearnUrl() {
        XCTAssertEqual(
            WebSessionCookieParser.learnUrl(baseUrl: "school.seqta.com.au"),
            "https://school.seqta.com.au/seqta/learn"
        )
    }
}
