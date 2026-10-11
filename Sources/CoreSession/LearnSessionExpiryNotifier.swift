import Foundation

/// Broadcast when the SEQTA session is no longer valid (401/403 or logout payload).
public enum LearnSessionExpiryNotifier {
    public static let notification = Notification.Name("LearnSessionExpired")

    public static func post() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}
