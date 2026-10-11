import Foundation

/// Posted when inbox unread state may have changed (e.g. message opened in FeatureMessages).
public enum LearnInboxDidChangeNotifier {
    public static let notification = Notification.Name("LearnInboxDidChange")

    public static func post() {
        NotificationCenter.default.post(name: notification, object: nil)
    }
}
