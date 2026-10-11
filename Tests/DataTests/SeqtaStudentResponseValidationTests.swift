import CoreNetworking
import XCTest

final class SeqtaStudentResponseValidationTests: XCTestCase {
    func test401ThrowsSessionExpired() throws {
        let response = HTTPURLResponse(
            url: URL(string: "https://school.example/seqta/student/heartbeat")!,
            statusCode: 401,
            httpVersion: nil,
            headerFields: nil
        )!
        XCTAssertThrowsError(try SeqtaStudentResponseValidation.validate(data: Data(), response: response)) { error in
            XCTAssertEqual(error as? SeqtaStudentTransportError, .sessionExpired)
        }
    }

    func testLogoutPayloadThrowsSessionExpired() throws {
        let data = #"{"status":"logout"}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://school.example/seqta/student/load/subjects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        XCTAssertThrowsError(try SeqtaStudentResponseValidation.validate(data: data, response: response)) { error in
            XCTAssertEqual(error as? SeqtaStudentTransportError, .sessionExpired)
        }
    }

    func testSuccessPayloadPasses() throws {
        let data = #"{"payload":[]}"#.data(using: .utf8)!
        let response = HTTPURLResponse(
            url: URL(string: "https://school.example/seqta/student/load/subjects")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        XCTAssertNoThrow(try SeqtaStudentResponseValidation.validate(data: data, response: response))
    }
}

extension SeqtaStudentTransportError: Equatable {
    public static func == (lhs: SeqtaStudentTransportError, rhs: SeqtaStudentTransportError) -> Bool {
        switch (lhs, rhs) {
        case (.sessionExpired, .sessionExpired): true
        case let (.httpStatus(a), .httpStatus(b)): a == b
        case (.invalidResponse, .invalidResponse): true
        default: false
        }
    }
}
