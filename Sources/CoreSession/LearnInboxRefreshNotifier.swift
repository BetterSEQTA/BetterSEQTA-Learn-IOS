import Foundation

/// Posted when the user requests an inbox unread refresh from Settings (badge + tab bar).
public enum LearnInboxRefreshNotifier {
    public static let manualRefresh = Notification.Name("learn.inbox.manualRefresh")
    public static let pollIntervalDidChange = Notification.Name("learn.inbox.pollIntervalDidChange")
}
