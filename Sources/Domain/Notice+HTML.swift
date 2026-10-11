import Foundation

public extension Notice {
    /// Human-readable body with HTML tags and common entities removed.
    public var plainTextContents: String {
        HTMLPlainText.strip(contents)
    }

    /// Short line for list / home cards; nil when body is empty after stripping.
    public func contentPreview(maxLength: Int = 160) -> String? {
        let trimmed = plainTextContents
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: "\n", with: " ")
        guard !trimmed.isEmpty else { return nil }
        if trimmed.count <= maxLength { return trimmed }
        let end = trimmed.index(trimmed.startIndex, offsetBy: maxLength)
        var slice = String(trimmed[..<end])
        if let lastSpace = slice.lastIndex(of: " ") {
            slice = String(slice[..<lastSpace])
        }
        return slice.trimmingCharacters(in: .whitespaces) + "…"
    }
}

public enum HTMLPlainText {
    public static func strip(_ html: String) -> String {
        guard html.contains("<") || html.contains("&") else { return html }
        var text = html
        text = text.replacingOccurrences(
            of: "<(script|style)[^>]*>[\\s\\S]*?</\\1>",
            with: "",
            options: [.regularExpression, .caseInsensitive]
        )
        text = text.replacingOccurrences(of: "<br\\s*/?>", with: "\n", options: .regularExpression)
        text = text.replacingOccurrences(of: "</p>", with: "\n", options: .caseInsensitive)
        text = text.replacingOccurrences(of: "<[^>]+>", with: "", options: .regularExpression)
        text = decodeBasicEntities(text)
        text = text.replacingOccurrences(of: "[ \\t\\f\\v]+", with: " ", options: .regularExpression)
        text = text.replacingOccurrences(of: "\\n{3,}", with: "\n\n", options: .regularExpression)
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private static func decodeBasicEntities(_ value: String) -> String {
        var result = value
        let entities: [(String, String)] = [
            ("&nbsp;", " "),
            ("&amp;", "&"),
            ("&lt;", "<"),
            ("&gt;", ">"),
            ("&quot;", "\""),
            ("&#39;", "'"),
            ("&apos;", "'"),
        ]
        for (entity, character) in entities {
            result = result.replacingOccurrences(of: entity, with: character)
        }
        return result
    }
}
