import CoreSession
import Foundation
import Observation
import UserNotifications
import WidgetKit

@MainActor
@Observable
public final class LearnNotificationsSettingsViewModel {
    public var assessmentRemindersEnabled: Bool
    public var noticeAlertsEnabled: Bool
    public var authorizationStatus: UNAuthorizationStatus = .notDetermined
    public var widgetRefreshMessage: String?
    public var inboxRefreshMessage: String?
    public var isRequestingPermission = false
    public var inboxPollInterval: LearnInboxPollInterval

    private let preferences: LearnNotificationPreferencesStore
    private let inboxPollPreferences: LearnInboxPollPreferencesStore

    public init(
        preferences: LearnNotificationPreferencesStore = LearnNotificationPreferencesStore(),
        inboxPollPreferences: LearnInboxPollPreferencesStore = LearnInboxPollPreferencesStore()
    ) {
        self.preferences = preferences
        self.inboxPollPreferences = inboxPollPreferences
        assessmentRemindersEnabled = preferences.assessmentRemindersEnabled
        noticeAlertsEnabled = preferences.noticeAlertsEnabled
        inboxPollInterval = inboxPollPreferences.interval
    }

    public func refreshAuthorizationStatus() async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    public func setAssessmentRemindersEnabled(_ enabled: Bool) async {
        if enabled {
            let granted = await ensureNotificationPermission()
            guard granted else { return }
        }
        assessmentRemindersEnabled = enabled
        preferences.assessmentRemindersEnabled = enabled
        if !enabled {
            await LearnLocalNotificationPlanner.cancelAssessmentReminders()
        }
    }

    public func setNoticeAlertsEnabled(_ enabled: Bool) async {
        if enabled {
            let granted = await ensureNotificationPermission()
            guard granted else { return }
        }
        noticeAlertsEnabled = enabled
        preferences.noticeAlertsEnabled = enabled
    }

    public func refreshHomeScreenWidget() {
        WidgetCenter.shared.reloadAllTimelines()
        widgetRefreshMessage = "Widget refresh requested."
    }

    public func setInboxPollInterval(_ interval: LearnInboxPollInterval) {
        inboxPollInterval = interval
        inboxPollPreferences.interval = interval
        NotificationCenter.default.post(name: LearnInboxRefreshNotifier.pollIntervalDidChange, object: nil)
    }

    public func refreshMessageBadgeNow() {
        NotificationCenter.default.post(name: LearnInboxRefreshNotifier.manualRefresh, object: nil)
        inboxRefreshMessage = "Message badge refresh requested."
    }

    public var systemSettingsHint: String? {
        switch authorizationStatus {
        case .denied:
            return "Notifications are off in iOS Settings. Enable alerts to receive reminders."
        case .authorized, .provisional, .ephemeral:
            return nil
        case .notDetermined:
            return "Allow notifications when you turn on a reminder type."
        @unknown default:
            return nil
        }
    }

    private func ensureNotificationPermission() async -> Bool {
        isRequestingPermission = true
        defer { isRequestingPermission = false }
        let granted = await LearnNotificationsCoordinator.requestAuthorizationIfNeeded()
        await refreshAuthorizationStatus()
        return granted
    }
}
