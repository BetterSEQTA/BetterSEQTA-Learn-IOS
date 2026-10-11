import Foundation

struct LearnJwtExpiryPayload: Decodable {
    let exp: Int64
}

enum LearnJwtValidator {
    static func validate(token: String) -> LearnJwtExpiryPayload? {
        let parts = token.split(separator: ".")
        guard parts.count == 3 else { return nil }
        guard let segmentText = decodeSegment(String(parts[1])),
              let data = segmentText.data(using: .utf8),
              let payload = try? JSONDecoder().decode(LearnJwtExpiryPayload.self, from: data) else {
            return nil
        }
        let now = Int64(Date().timeIntervalSince1970)
        return payload.exp > now ? payload : nil
    }

    private static func decodeSegment(_ segment: String) -> String? {
        var padded = segment
        while padded.count % 4 != 0 { padded += "=" }
        let urlDecoded = Data(base64Encoded: padded, options: .ignoreUnknownCharacters)
        let standardDecoded = urlDecoded ?? Data(base64Encoded: padded)
        guard let bytes = standardDecoded else { return nil }
        return String(data: bytes, encoding: .utf8)
    }
}
