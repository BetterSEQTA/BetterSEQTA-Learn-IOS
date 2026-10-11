import FeatureAuth
import Foundation

/// In-app routing for Learn URL schemes when already authenticated.
/// Android `MainActivity` only forwards schemes to auth today; this adds minimal tab/overlay routing for future universal links.
enum LearnShellDeeplinkRoute: Equatable {
    case tab(ShellTab)
    case overlay(ShellOverlay)
}

enum LearnShellDeeplinkRouter {
    private static let shellSchemes: Set<String> = ["seqtalearn", "seqta", "betterseqtalearn"]

    static func parse(_ link: String) -> LearnShellDeeplinkRoute? {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !isAuthDeeplink(trimmed),
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased(),
              shellSchemes.contains(scheme) else {
            return nil
        }

        let host = url.host?.lowercased() ?? ""
        let path = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/")).lowercased()
        let pathSegment = path.split(separator: "/").first.map(String.init)
        let segment = pathSegment ?? (host.isEmpty ? nil : host)
        guard let segment else { return nil }

        switch segment {
        case "home", "dashboard":
            return .tab(.home)
        case "timetable", "calendar":
            return .tab(.timetable)
        case "courses", "subjects":
            return .tab(.courses)
        case "tasks", "assessments", "assessment":
            return .tab(.tasks)
        case "messages", "message", "inbox":
            return .tab(.messages)
        case "portals", "portal":
            return .overlay(.portals)
        case "notices", "notice":
            return .overlay(.notices)
        case "settings":
            return .overlay(.settings)
        default:
            return nil
        }
    }

    static func isAuthDeeplink(_ link: String) -> Bool {
        isValidAuthDeeplink(link)
    }
}
