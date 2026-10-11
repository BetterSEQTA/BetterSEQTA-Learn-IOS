import SwiftUI

public enum LearnSubjectColour {
    private static let defaultColour = Color(red: 0.23, green: 0.51, blue: 0.96)
    nonisolated(unsafe) private static var cache: [String: Color] = [:]

    public static func parse(_ raw: String?) -> Color {
        guard let raw, !raw.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return defaultColour
        }
        let key = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if let cached = cache[key] { return cached }
        let colour = parseUncached(key)
        cache[key] = colour
        return colour
    }

    private static func parseUncached(_ raw: String) -> Color {
        let normalized = raw.hasPrefix("#") ? String(raw.dropFirst()) : raw
        guard let value = UInt64(normalized, radix: 16) else { return defaultColour }
        switch normalized.count {
        case 6:
            let r = Double((value >> 16) & 0xFF) / 255
            let g = Double((value >> 8) & 0xFF) / 255
            let b = Double(value & 0xFF) / 255
            return Color(red: r, green: g, blue: b)
        case 8:
            let a = Double((value >> 24) & 0xFF) / 255
            let r = Double((value >> 16) & 0xFF) / 255
            let g = Double((value >> 8) & 0xFF) / 255
            let b = Double(value & 0xFF) / 255
            return Color(red: r, green: g, blue: b, opacity: a)
        default:
            return defaultColour
        }
    }
}
