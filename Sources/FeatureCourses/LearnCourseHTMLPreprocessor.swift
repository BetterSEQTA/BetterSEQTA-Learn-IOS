import Domain
import Foundation

/// SEQTA legacy course HTML tokens and inline styles from the web editor.
enum LearnCourseHTMLPreprocessor {
    private static let resourceTokenPattern =
        #"\[\[resource:([^\]|]+)(?:\|([^\]]*))?\]\]"#

    static func prepare(
        _ html: String,
        courseFiles: [CourseResourceFile],
        headerImageUUID: String?
    ) -> String {
        var result = html
        result = replaceThemeImprint(in: result, headerImageUUID: headerImageUUID)
        result = replaceResourceTokens(in: result, courseFiles: courseFiles)
        result = replaceBareThemeTokens(in: result)
        return result
    }

    private static func replaceThemeImprint(in html: String, headerImageUUID: String?) -> String {
        let token = "[[theme:imprint]]"
        guard html.contains(token) else { return html }
        let replacement: String
        // Banner image is shown in the native course header; drop the web placeholder.
        replacement = ""
        return html.replacingOccurrences(of: token, with: replacement)
    }

    private static func replaceBareThemeTokens(in html: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: #"\[\[theme:[^\]]+\]\]"#) else { return html }
        let range = NSRange(html.startIndex ..< html.endIndex, in: html)
        return regex.stringByReplacingMatches(in: html, range: range, withTemplate: "")
    }

    private static func replaceResourceTokens(in html: String, courseFiles: [CourseResourceFile]) -> String {
        guard let regex = try? NSRegularExpression(pattern: resourceTokenPattern) else { return html }
        let nsRange = NSRange(html.startIndex ..< html.endIndex, in: html)
        let matches = regex.matches(in: html, range: nsRange)
        guard !matches.isEmpty else { return html }

        var result = html
        for match in matches.reversed() {
            guard let swiftRange = Range(match.range, in: result),
                  let filenameRange = Range(match.range(at: 1), in: result) else { continue }
            let filename = String(result[filenameRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            let label: String
            if match.numberOfRanges > 2, let labelRange = Range(match.range(at: 2), in: result) {
                label = String(result[labelRange]).trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                label = ""
            }
            let display = label.isEmpty ? filename : label
            let linkHTML = resourceLinkHTML(filename: filename, display: display, courseFiles: courseFiles)
            result.replaceSubrange(swiftRange, with: linkHTML)
        }
        return result
    }

    private static func resourceLinkHTML(
        filename: String,
        display: String,
        courseFiles: [CourseResourceFile]
    ) -> String {
        let normalized = filename.trimmingCharacters(in: .whitespacesAndNewlines)
        let file = courseFiles.first { file in
            file.filename.caseInsensitiveCompare(normalized) == .orderedSame
                || file.filename.localizedCaseInsensitiveContains(normalized)
                || normalized.localizedCaseInsensitiveContains(file.filename)
        }
        let title = display.isEmpty ? (file?.filename ?? normalized) : display
        guard let file else {
            return "<span class=\"course-file-missing\">📎 \(escapeHTML(title))</span>"
        }
        let url = "learnseqta-course-file://\(file.uuid)"
        return "<a href=\"\(url)\" class=\"course-file-link\">📎 \(escapeHTML(title))</a>"
    }

    private static func escapeHTML(_ text: String) -> String {
        text
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
    }
}
