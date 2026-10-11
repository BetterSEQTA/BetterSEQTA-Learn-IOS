import Foundation

/// Local toggles aligned with Android settings preferences (persisted only; scheduling TBD).
@MainActor
public final class LearnNotificationPreferencesStore {
    private enum Keys {
        static let assessmentReminders = "learn.notifications.assessmentRemindersEnabled"
        static let noticeAlerts = "learn.notifications.noticeAlertsEnabled"
    }

    private let defaults: UserDefaults

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public var assessmentRemindersEnabled: Bool {
        get { defaults.object(forKey: Keys.assessmentReminders) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.assessmentReminders) }
    }

    public var noticeAlertsEnabled: Bool {
        get { defaults.object(forKey: Keys.noticeAlerts) as? Bool ?? true }
        set { defaults.set(newValue, forKey: Keys.noticeAlerts) }
    }
}
