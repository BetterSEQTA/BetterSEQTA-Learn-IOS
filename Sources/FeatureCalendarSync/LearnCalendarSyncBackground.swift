import BackgroundTasks
import Foundation

/// BGAppRefresh parity for Android `TimetableCalendarSyncWorker` (~24h, best-effort on iOS).
@MainActor
public enum LearnCalendarSyncBackground {
    public static let taskIdentifier = "org.betterseqta.learn.calendar-sync"

    private static var syncHandler: (@MainActor () async -> Void)?
    private static var didRegister = false

    public static func configure(syncHandler: @escaping @MainActor () async -> Void) {
        self.syncHandler = syncHandler
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
                await syncHandler?()
                refreshTask.setTaskCompleted(success: true)
                scheduleAutoSync(enabled: true)
            }
        }
    }

    public static func scheduleAutoSync(enabled: Bool) {
        BGTaskScheduler.shared.cancel(taskRequestWithIdentifier: taskIdentifier)
        guard enabled else { return }
        let request = BGAppRefreshTaskRequest(identifier: taskIdentifier)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 24 * 60 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
