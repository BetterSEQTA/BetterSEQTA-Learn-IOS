import Foundation

/// Low-level SEQTA login HTTP (mirrors Android `AuthRepositoryImpl` request builder).
enum AuthLoginTransport {
    private static let userAgent = "Mozilla/5.0 (BetterSEQTALearnIOS)"

    static func postJSON(
        url: String,
        body: String,
        jsessionId: String? = nil,
        bearer: String? = nil,
        userNumber: String? = nil
    ) async throws -> String? {
        let request = buildRequest(url: url, body: body, jsessionId: jsessionId, bearer: bearer, userNumber: userNumber)
        let (_, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthLoginError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw AuthLoginError.httpStatus(http.statusCode)
        }
        return http.value(forHTTPHeaderField: "Set-Cookie")
    }

    static func postJSONWithResponse(
        url: String,
        body: String,
        jsessionId: String? = nil,
        bearer: String? = nil,
        userNumber: String? = nil
    ) async throws -> (Data, HTTPURLResponse) {
        let request = buildRequest(url: url, body: body, jsessionId: jsessionId, bearer: bearer, userNumber: userNumber)
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw AuthLoginError.invalidResponse
        }
        guard (200 ... 299).contains(http.statusCode) else {
            throw AuthLoginError.httpStatus(http.statusCode)
        }
        return (data, http)
    }

    private static func buildRequest(
        url: String,
        body: String,
        jsessionId: String?,
        bearer: String?,
        userNumber: String?
    ) -> URLRequest {
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "POST"
        request.httpBody = body.data(using: .utf8)
        let origin = AuthURLHelpers.extractOrigin(from: url)
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue(origin, forHTTPHeaderField: "Origin")
        request.setValue(origin, forHTTPHeaderField: "Referer")
        if let jsessionId {
            if jsessionId.hasPrefix("eyJ") {
                request.setValue("Bearer \(jsessionId)", forHTTPHeaderField: "Authorization")
                request.setValue("JSESSIONID=\(jsessionId)", forHTTPHeaderField: "Cookie")
            } else {
                request.setValue("JSESSIONID=\(jsessionId)", forHTTPHeaderField: "Cookie")
            }
        }
        if let bearer {
            request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
        }
        if let userNumber {
            request.setValue(userNumber, forHTTPHeaderField: "X-User-Number")
        }
        return request
    }
}

enum AuthLoginError: Error {
    case invalidResponse
    case httpStatus(Int)
    case missingSessionCookie
}
