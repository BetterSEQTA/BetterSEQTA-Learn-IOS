import Foundation
import UserNotifications

/// Registers notification categories and requests authorization (skeleton for push/local alerts).
public enum LearnNotificationsCoordinator {
    public static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
        @unknown default:
            return false
        }
    }

    public static func registerCategories() {
        let category = UNNotificationCategory(
            identifier: "learn.assessment.reminder",
            actions: [],
            intentIdentifiers: [],
            options: []
        )
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}
