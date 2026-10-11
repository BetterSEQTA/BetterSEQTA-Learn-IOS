import CoreSession
import Foundation

public enum LearnSeqtaRequestError: Error, Sendable {
    case invalidURL
    case invalidBody
    case invalidResponse
    case httpStatus(Int)
}

public struct LearnSeqtaPOSTOptions: Sendable {
    public var jsessionId: String?
    public var bearer: String?
    public var userNumber: String?

    public init(jsessionId: String? = nil, bearer: String? = nil, userNumber: String? = nil) {
        self.jsessionId = jsessionId
        self.bearer = bearer
        self.userNumber = userNumber
    }
}

public func learnSeqtaNormalizeBaseURL(_ baseUrl: String) -> String {
    let trimmed = baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: "/$", with: "", options: .regularExpression)
    if trimmed.hasPrefix("https://") || trimmed.hasPrefix("http://") {
        return trimmed
    }
    return "https://\(trimmed)"
}

public func learnSeqtaParseJSessionID(from response: HTTPURLResponse) -> String? {
    let candidates = response.allHeaderFields.compactMap { key, value -> String? in
        guard let key = key as? String, key.lowercased() == "set-cookie" else { return nil }
        return value as? String
    }
    for cookie in candidates {
        if let parsed = parseJSessionFromSetCookie(cookie) { return parsed }
    }
    if let combined = response.value(forHTTPHeaderField: "Set-Cookie") {
        return parseJSessionFromSetCookie(combined)
    }
    return nil
}

public func parseJSessionFromSetCookie(_ setCookie: String) -> String? {
    for part in setCookie.split(separator: ";") {
        let trimmed = part.trimmingCharacters(in: .whitespaces)
        if trimmed.hasPrefix("JSESSIONID=") {
            return String(trimmed.dropFirst("JSESSIONID=".count))
        }
    }
    return nil
}

/// JSON POST helper for SEQTA student endpoints with `JSESSIONID` cookie / JWT bearer.
public func learnSeqtaPOST(
    baseURL: URL,
    path: String,
    body: [String: any Sendable],
    options: LearnSeqtaPOSTOptions = LearnSeqtaPOSTOptions()
) async throws -> (Data, HTTPURLResponse) {
    let baseString = baseURL.absoluteString
    let trimmed = baseString.hasSuffix("/") ? String(baseString.dropLast()) : baseString
    let pathNormalized = path.hasPrefix("/") ? path : "/" + path
    guard let url = URL(string: trimmed + pathNormalized) else {
        throw LearnSeqtaRequestError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
    request.setValue("Mozilla/5.0 (BetterSEQTALearnIOS)", forHTTPHeaderField: "User-Agent")
    if let origin = learnSeqtaOrigin(from: url) {
        request.setValue(origin, forHTTPHeaderField: "Origin")
        request.setValue(origin, forHTTPHeaderField: "Referer")
    }

    if let jsessionId = options.jsessionId, !jsessionId.isEmpty {
        request.setValue("JSESSIONID=\(jsessionId)", forHTTPHeaderField: "Cookie")
        if jsessionId.hasPrefix("eyJ") {
            request.setValue("Bearer \(jsessionId)", forHTTPHeaderField: "Authorization")
        }
    }
    if let bearer = options.bearer, !bearer.isEmpty {
        request.setValue("Bearer \(bearer)", forHTTPHeaderField: "Authorization")
    }
    if let userNumber = options.userNumber {
        request.setValue(userNumber, forHTTPHeaderField: "X-User-Number")
    }

    let jsonObject = body.reduce(into: [String: Any]()) { partial, entry in
        partial[entry.key] = entry.value
    }
    guard JSONSerialization.isValidJSONObject(jsonObject),
          let bodyData = try? JSONSerialization.data(withJSONObject: jsonObject) else {
        throw LearnSeqtaRequestError.invalidBody
    }
    request.httpBody = bodyData

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw LearnSeqtaRequestError.invalidResponse
    }
    return (data, httpResponse)
}

public func learnSeqtaPOST(
    session: LearnSession,
    path: String,
    body: [String: any Sendable]
) async throws -> (Data, HTTPURLResponse) {
    try await learnSeqtaPOST(
        baseURL: session.baseURL,
        path: path,
        body: body,
        options: LearnSeqtaPOSTOptions(jsessionId: session.jsessionId, bearer: session.jsessionId.hasPrefix("eyJ") ? session.jsessionId : nil)
    )
}

/// Authenticated GET for binary SEQTA resources (e.g. message attachments).
public func learnSeqtaGET(
    session: LearnSession,
    path: String,
    queryItems: [URLQueryItem] = []
) async throws -> (Data, HTTPURLResponse) {
    let baseString = session.baseURL.absoluteString
    let trimmed = baseString.hasSuffix("/") ? String(baseString.dropLast()) : baseString
    let pathNormalized = path.hasPrefix("/") ? path : "/" + path
    var components = URLComponents(string: trimmed + pathNormalized)
    if !queryItems.isEmpty {
        components?.queryItems = queryItems
    }
    guard let url = components?.url else {
        throw LearnSeqtaRequestError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
    request.setValue("Mozilla/5.0 (BetterSEQTALearnIOS)", forHTTPHeaderField: "User-Agent")
    if let origin = learnSeqtaOrigin(from: url) {
        request.setValue(origin, forHTTPHeaderField: "Origin")
        request.setValue(origin, forHTTPHeaderField: "Referer")
    }

    let jsessionId = session.jsessionId
    if !jsessionId.isEmpty {
        request.setValue("JSESSIONID=\(jsessionId)", forHTTPHeaderField: "Cookie")
        if jsessionId.hasPrefix("eyJ") {
            request.setValue("Bearer \(jsessionId)", forHTTPHeaderField: "Authorization")
        }
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw LearnSeqtaRequestError.invalidResponse
    }
    return (data, httpResponse)
}

/// Raw file upload for message compose (`/seqta/student/file/upload/xhr2`, DesQTA parity).
public func learnSeqtaUploadFile(
    session: LearnSession,
    filename: String,
    fileData: Data
) async throws -> (Data, HTTPURLResponse) {
    let baseString = session.baseURL.absoluteString
    let trimmed = baseString.hasSuffix("/") ? String(baseString.dropLast()) : baseString
    let path = "/seqta/student/file/upload/xhr2"
    guard let url = URL(string: trimmed + path) else {
        throw LearnSeqtaRequestError.invalidURL
    }

    let encodedName =
        filename.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? filename

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.httpBody = fileData
    request.setValue(encodedName, forHTTPHeaderField: "X-File-Name")
    request.setValue("null", forHTTPHeaderField: "X-Accept-Mimes")
    request.setValue("XMLHttpRequest", forHTTPHeaderField: "X-Requested-With")
    request.setValue("application/octet-stream", forHTTPHeaderField: "Content-Type")
    request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
    request.setValue("Mozilla/5.0 (BetterSEQTALearnIOS)", forHTTPHeaderField: "User-Agent")
    if let origin = learnSeqtaOrigin(from: url) {
        request.setValue(origin, forHTTPHeaderField: "Origin")
        request.setValue(origin, forHTTPHeaderField: "Referer")
    }

    let jsessionId = session.jsessionId
    if !jsessionId.isEmpty {
        request.setValue("JSESSIONID=\(jsessionId)", forHTTPHeaderField: "Cookie")
        if jsessionId.hasPrefix("eyJ") {
            request.setValue("Bearer \(jsessionId)", forHTTPHeaderField: "Authorization")
        }
    }

    let (data, response) = try await URLSession.shared.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
        throw LearnSeqtaRequestError.invalidResponse
    }
    return (data, httpResponse)
}

private func learnSeqtaOrigin(from url: URL) -> String? {
    guard let host = url.host else { return nil }
    let scheme = url.scheme ?? "https"
    if let port = url.port, port != 80, port != 443 {
        return "\(scheme)://\(host):\(port)"
    }
    return "\(scheme)://\(host)"
}
