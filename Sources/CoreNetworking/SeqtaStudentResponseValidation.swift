import Foundation

public enum SeqtaStudentTransportError: Error, Sendable {
    case sessionExpired
    case httpStatus(Int)
    case invalidResponse
}

/// Validates SEQTA student API responses (mirrors Android session-expiry handling).
public enum SeqtaStudentResponseValidation {
    private static let sessionExpiredBodyMarkers = [
        "session expired",
        "not logged in",
        "login required",
        "unauthorized",
        "\"status\":\"logout\"",
        "\"status\": \"logout\"",
    ]

    public static func validate(data: Data, response: HTTPURLResponse) throws {
        let code = response.statusCode
        if code == 401 || code == 403 {
            throw SeqtaStudentTransportError.sessionExpired
        }
        if !(200 ... 299).contains(code) {
            throw SeqtaStudentTransportError.httpStatus(code)
        }
        if indicatesSessionExpiredInBody(data) {
            throw SeqtaStudentTransportError.sessionExpired
        }
    }

    private static func indicatesSessionExpiredInBody(_ data: Data) -> Bool {
        guard !data.isEmpty,
              let text = String(data: data, encoding: .utf8)?.lowercased() else {
            return false
        }
        if sessionExpiredBodyMarkers.contains(where: { text.contains($0) }) {
            return true
        }
        if let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            if let status = root["status"] as? String,
               status.lowercased() == "logout" || status.lowercased() == "unauthorized" {
                return true
            }
            if let message = root["message"] as? String,
               message.lowercased().contains("session") && message.lowercased().contains("expir") {
                return true
            }
        }
        return false
    }
}
