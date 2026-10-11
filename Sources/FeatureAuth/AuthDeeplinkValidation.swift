import Foundation

public func isValidAuthDeeplink(_ value: String) -> Bool {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.hasPrefix("seqtalearn://sso/")
        || trimmed.hasPrefix("seqta://sso/")
        || trimmed.hasPrefix("desqta://connect/")
        || trimmed.hasPrefix("betterseqtalearn://connect/")
}

public func authDeeplinkError(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty { return "Paste a SEQTA or BetterSEQTA+ connect link." }
    if trimmed.hasPrefix("seqtalearn://"), !trimmed.hasPrefix("seqtalearn://sso/") {
        return "Invalid SEQTA link. Scan the QR from your SEQTA email or welcome page."
    }
    if trimmed.hasPrefix("desqta://"), !trimmed.hasPrefix("desqta://connect/") {
        return "Invalid connect link. Generate a new QR from BetterSEQTA+ Settings."
    }
    if !isValidAuthDeeplink(trimmed) {
        return "Unrecognised link. Use a SEQTA SSO QR or BetterSEQTA+ connect QR."
    }
    return nil
}
