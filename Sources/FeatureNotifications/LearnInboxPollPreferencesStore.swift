import Foundation

/// Foreground inbox badge refresh interval (Android uses WorkManager for notices/assessments, not inbox polling).
public enum LearnInboxPollInterval: Int, CaseIterable, Sendable {
    case manualOnly = 0
    case fiveMinutes = 300
    case fifteenMinutes = 900
    case thirtyMinutes = 1800

    public var label: String {
        switch self {
        case .manualOnly: "Manual & app resume only"
        case .fiveMinutes: "Every 5 minutes (app open)"
        case .fifteenMinutes: "Every 15 minutes (app open)"
        case .thirtyMinutes: "Every 30 minutes (app open)"
        }
    }

    public var seconds: Int { rawValue }
}

@MainActor
public final class LearnInboxPollPreferencesStore {
    private enum Keys {
        static let intervalSeconds = "learn.notifications.inboxPollIntervalSeconds"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var interval: LearnInboxPollInterval {
        get {
            let raw = defaults.object(forKey: Keys.intervalSeconds) as? Int ?? LearnInboxPollInterval.manualOnly.rawValue
            return LearnInboxPollInterval(rawValue: raw) ?? .manualOnly
        }
        set {
            defaults.set(newValue.rawValue, forKey: Keys.intervalSeconds)
        }
    }
}
