import Foundation

struct SeqtaSsoPayload: Decodable, Sendable {
    let t: String
    let u: String
    let n: String
}

struct ConnectPayload: Decodable, Sendable {
    let u: String
    let s: String
}

struct JwtPayload: Decodable, Sendable {
    let exp: Int64
}

enum AuthDeeplinkParser {
    static func parseSsoDeeplink(_ deeplink: String) -> SeqtaSsoPayload? {
        let prefix: String?
        if deeplink.hasPrefix("seqtalearn://sso/") {
            prefix = "seqtalearn://sso/"
        } else if deeplink.hasPrefix("seqta://sso/") {
            prefix = "seqta://sso/"
        } else {
            prefix = nil
        }
        guard let prefix else { return nil }
        return decodePayload(String(deeplink.dropFirst(prefix.count)))
    }

    static func parseConnectDeeplink(_ deeplink: String) -> ConnectPayload? {
        let prefix: String?
        if deeplink.hasPrefix("desqta://connect/") {
            prefix = "desqta://connect/"
        } else if deeplink.hasPrefix("betterseqtalearn://connect/") {
            prefix = "betterseqtalearn://connect/"
        } else {
            prefix = nil
        }
        guard let prefix else { return nil }
        return decodePayload(String(deeplink.dropFirst(prefix.count)))
    }

    private static func decodePayload<T: Decodable>(_ encoded: String) -> T? {
        guard let urlDecoded = encoded.removingPercentEncoding,
              let data = Data(base64Encoded: urlDecoded),
              let json = String(data: data, encoding: .utf8) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: json.data(using: .utf8)!)
    }
}

enum AuthJwtValidator {
    static func validate(token: String) -> JwtPayload? {
        let parts = token.split(separator: ".", omittingEmptySubsequences: false)
        guard parts.count == 3 else { return nil }
        var segment = String(parts[1])
        while segment.count % 4 != 0 { segment.append("=") }
        let bytes = Data(base64Encoded: segment, options: .ignoreUnknownCharacters)
            ?? Data(base64Encoded: segment)
        guard let bytes,
              let decoded = String(data: bytes, encoding: .utf8),
              let jwt = try? JSONDecoder().decode(JwtPayload.self, from: Data(decoded.utf8)) else {
            return nil
        }
        let now = Int64(Date().timeIntervalSince1970)
        return jwt.exp > now ? jwt : nil
    }
}

enum AuthURLHelpers {
    static func normalizeBaseUrl(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasPrefix("https://") || trimmed.hasPrefix("http://") {
            return trimmed
        }
        return trimmed.isEmpty ? "" : "https://\(trimmed)"
    }

    static func extractOrigin(from urlString: String) -> String {
        guard let url = URL(string: urlString), let host = url.host else { return urlString }
        let scheme = url.scheme ?? "https"
        if let port = url.port, port != 80, port != 443 {
            return "\(scheme)://\(host):\(port)"
        }
        return "\(scheme)://\(host)"
    }

    static func parseSetCookie(_ setCookie: String?) -> String? {
        guard let setCookie else { return nil }
        for part in setCookie.split(separator: ";") {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.uppercased().hasPrefix("JSESSIONID=") {
                let value = trimmed.dropFirst("JSESSIONID=".count)
                return value.isEmpty ? nil : String(value)
            }
        }
        return nil
    }
}
