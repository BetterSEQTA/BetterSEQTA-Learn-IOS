import BackgroundTasks
import Foundation

/// BGAppRefresh parity for Android notice/assessment workers (~2h, best-effort).
@MainActor
public enum LearnHomeBackgroundRefresh {
    public static let taskIdentifier = "org.betterseqta.learn.home-sync"

    private static var refreshHandler: (@MainActor () async -> Void)?
    private static var didRegister = false

    public static func configure(refreshHandler: @escaping @MainActor () async -> Void) {
        self.refreshHandler = refreshHandler
    }

    public static func registerIfNeeded() {
        guard !didRegister else { return }
        didRegister = true
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskIdentifier, using: nil) { task in
            guard let refreshTask = task as? BGAppRefreshTask else {
                task.setTaskCompleted(success: false)
                return
            }
            refreshTask.expirationHandler = {
                refreshTask.setTaskCompleted(success: false)
            }
            Task { @MainActor in
                await refreshHandler?()
                refreshTask.setTaskCompleted(success: true)
                schedulePeriodicSync(enabled: true)
            }
        }
    }

    public static func schedulePeriodicSync(enabled: Bool) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        guard enabled else { return }
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 2 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
