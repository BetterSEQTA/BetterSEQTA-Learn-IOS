import CoreCommon
import CoreSession
import Domain
import Foundation
import UserNotifications

@MainActor
final class MainShellViewModel: ObservableObject {
    @Published var unreadMessageCount = 0

    private let studentRepository: StudentRepository
    private var inboxChangeTask: Task<Void, Never>?
    private var manualRefreshTask: Task<Void, Never>?

    init(studentRepository: StudentRepository) {
        self.studentRepository = studentRepository
        inboxChangeTask = Task { @MainActor [weak self] in
            let stream = NotificationCenter.default.notifications(
                named: LearnInboxDidChangeNotifier.notification
            )
            for await _ in stream {
                guard !Task.isCancelled else { return }
                self?.refreshUnreadMessages()
            }
        }
        manualRefreshTask = Task { @MainActor [weak self] in
            let stream = NotificationCenter.default.notifications(
                named: LearnInboxRefreshNotifier.manualRefresh
            )
            for await _ in stream {
                guard !Task.isCancelled else { return }
                self?.refreshUnreadMessages()
            }
        }
    }

    deinit {
        inboxChangeTask?.cancel()
        manualRefreshTask?.cancel()
    }

    func refreshUnreadMessages() {
        Task {
            let result = await studentRepository.getMessages(
                folder: .inbox,
                searchValue: "",
                offset: 0,
                limit: 100
            )
            if case let .success(messages) = result {
                let count = messages.filter(\.unread).count
                unreadMessageCount = count
                await applyAppIconBadge(count: count)
            }
        }
    }

    private func applyAppIconBadge(count: Int) async {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        guard settings.authorizationStatus == .authorized
            || settings.authorizationStatus == .provisional
            || settings.authorizationStatus == .ephemeral else {
            return
        }
        try? await UNUserNotificationCenter.current().setBadgeCount(count)
    }

    func onAppResumed() {
        Task {
            _ = await studentRepository.sendHeartbeat()
            refreshUnreadMessages()
        }
    }
}
