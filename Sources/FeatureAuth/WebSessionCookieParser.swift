import Foundation

public enum WebSessionCookieParser {
    public static func parseJsessionId(cookieHeader: String?) -> String? {
        guard let cookieHeader, !cookieHeader.isBlank else { return nil }
        for part in cookieHeader.split(separator: ";") {
            let trimmed = part.trimmingCharacters(in: .whitespaces)
            if trimmed.lowercased().hasPrefix("jsessionid=") {
                let value = String(trimmed.dropFirst("JSESSIONID=".count))
                return value.isEmpty ? nil : value
            }
        }
        return nil
    }

    public static func normalizeSchoolBaseUrl(_ url: String) -> String {
        let trimmed = url.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        if trimmed.hasPrefix("https://") || trimmed.hasPrefix("http://") {
            return trimmed
        }
        return trimmed.isEmpty ? "" : "https://\(trimmed)"
    }

    public static func learnUrl(baseUrl: String) -> String {
        "\(normalizeSchoolBaseUrl(baseUrl))/seqta/learn"
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
