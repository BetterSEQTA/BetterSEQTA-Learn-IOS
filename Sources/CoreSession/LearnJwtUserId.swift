import Foundation

public func extractUserIdFromJwt(_ token: String) -> Int? {
    guard token.hasPrefix("eyJ") else { return nil }
    let parts = token.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 3 else { return nil }
    guard let payloadText = decodeJwtSegment(String(parts[1])) else { return nil }
    guard let data = payloadText.data(using: .utf8),
          let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
        return nil
    }
    for key in ["sub", "id", "userID", "userId", "student", "person"] {
        if let value = object[key] as? Int { return value }
        if let value = object[key] as? NSNumber { return value.intValue }
        if let value = object[key] as? String, let parsed = Int(value) { return parsed }
    }
    return nil
}

private func decodeJwtSegment(_ segment: String) -> String? {
    var padded = segment
    while padded.count % 4 != 0 { padded.append("=") }
    let urlDecoded = Data(base64Encoded: padded, options: .ignoreUnknownCharacters)
    let standardDecoded = urlDecoded ?? Data(base64Encoded: padded)
    guard let bytes = standardDecoded else { return nil }
    return String(data: bytes, encoding: .utf8)
}
