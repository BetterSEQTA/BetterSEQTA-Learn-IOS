import CoreDesign
import Domain
import SwiftUI

enum LearnCourseThemeStyle {
    static func resolve(
        content: CourseContent,
        catalog: [CourseDocumentTheme],
        subjectAccent: Color
    ) -> ResolvedCourseTheme {
        let matched = content.themeReference.flatMap { ref in
            catalog.first { $0.id == ref || $0.name == ref }
        }
        if let matched {
            return ResolvedCourseTheme(
                accent: color(from: matched.accentColour, fallback: subjectAccent),
                accentContrast: color(from: matched.accentContrastColour, fallback: .white),
                text: color(from: matched.textColour, fallback: LearnTheme.Colors.primaryText),
                pageBackground: color(from: matched.documentBackground, fallback: LearnTheme.Colors.background),
                cardBackground: color(from: matched.cardBackground, fallback: LearnTheme.Colors.card),
                moduleBackground: color(from: matched.moduleBackground, fallback: LearnTheme.Colors.card),
                headerImageUUID: matched.applyImage ? matched.headerImageUUID : nil
            )
        }
        let header = content.headerImageUUID
        return ResolvedCourseTheme(
            accent: subjectAccent,
            accentContrast: .white,
            text: LearnTheme.Colors.primaryText,
            pageBackground: LearnTheme.Colors.background,
            cardBackground: LearnTheme.Colors.card,
            moduleBackground: LearnTheme.Colors.card,
            headerImageUUID: header
        )
    }

    static func color(from css: String, fallback: Color) -> Color {
        let trimmed = css.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty { return fallback }
        if let hex = firstHex(in: trimmed) {
            return Color(hex: hex) ?? fallback
        }
        if trimmed.lowercased().hasPrefix("rgb") {
            return parseRGB(trimmed) ?? fallback
        }
        return fallback
    }

    private static func firstHex(in css: String) -> String? {
        let pattern = #"#[0-9A-Fa-f]{3,8}"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(css.startIndex ..< css.endIndex, in: css)
        guard let match = regex.firstMatch(in: css, range: range),
              let swiftRange = Range(match.range, in: css) else { return nil }
        return String(css[swiftRange])
    }

    private static func parseRGB(_ css: String) -> Color? {
        let digits = css
            .replacingOccurrences(of: "rgba", with: "")
            .replacingOccurrences(of: "rgb", with: "")
            .replacingOccurrences(of: "(", with: "")
            .replacingOccurrences(of: ")", with: "")
            .split(separator: ",")
            .compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
        guard digits.count >= 3 else { return nil }
        let alpha = digits.count > 3 ? digits[3] : 1
        return Color(red: digits[0] / 255, green: digits[1] / 255, blue: digits[2] / 255, opacity: alpha)
    }
}

struct ResolvedCourseTheme {
    let accent: Color
    let accentContrast: Color
    let text: Color
    let pageBackground: Color
    let cardBackground: Color
    let moduleBackground: Color
    let headerImageUUID: String?
}

private extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if hexSanitized.hasPrefix("#") { hexSanitized.removeFirst() }
        guard hexSanitized.count == 6 || hexSanitized.count == 8 else { return nil }
        var value: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&value) else { return nil }
        let r, g, b, a: Double
        if hexSanitized.count == 8 {
            r = Double((value & 0xFF00_0000) >> 24) / 255
            g = Double((value & 0x00FF_0000) >> 16) / 255
            b = Double((value & 0x0000_FF00) >> 8) / 255
            a = Double(value & 0x0000_00FF) / 255
        } else {
            r = Double((value & 0xFF0000) >> 16) / 255
            g = Double((value & 0x00FF00) >> 8) / 255
            b = Double(value & 0x0000FF) / 255
            a = 1
        }
        self.init(red: r, green: g, blue: b, opacity: a)
    }
}
