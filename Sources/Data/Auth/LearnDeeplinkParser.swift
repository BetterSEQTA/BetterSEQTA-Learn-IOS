import Foundation

struct LearnSeqtaSsoPayload: Decodable {
    let t: String
    let u: String
    let n: String
}

struct LearnConnectPayload: Decodable {
    let u: String
    let s: String
}

enum LearnDeeplinkParser {
    static func parseSsoDeeplink(_ deeplink: String) -> LearnSeqtaSsoPayload? {
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

    static func parseConnectDeeplink(_ deeplink: String) -> LearnConnectPayload? {
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
              let data = Data(base64Encoded: urlDecoded) else {
            return nil
        }
        return try? JSONDecoder().decode(T.self, from: data)
    }
}
