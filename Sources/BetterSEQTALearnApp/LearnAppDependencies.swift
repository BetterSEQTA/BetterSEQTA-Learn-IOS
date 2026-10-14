import CoreSession
import Data
import Domain
import FeatureHome
import Foundation

@MainActor
public final class LearnAppDependencies: ObservableObject {
    public let sessionStore: LearnSessionStore
    public let authRepository: AuthRepository
    public let studentRepository: StudentRepository
    public let calendarSyncRepository: CalendarSyncRepository
    public let homeLaunchGate: HomeLaunchGate

    private var sessionExpiryTask: Task<Void, Never>?

    public init(sessionStore: LearnSessionStore) {
        self.sessionStore = sessionStore
        self.homeLaunchGate = HomeLaunchGate()
        self.authRepository = DataModule.makeAuthRepository(sessionStore: sessionStore)
        self.studentRepository = DataModule.makeStudentRepository { [weak sessionStore] in
            sessionStore?.currentSession() ?? SessionData()
        }
        self.calendarSyncRepository = DataModule.makeCalendarSyncRepository(
            studentRepository: studentRepository
        )
        sessionExpiryTask = Task { @MainActor [weak self] in
            let stream = NotificationCenter.default.notifications(
                named: LearnSessionExpiryNotifier.notification
            )
            for await _ in stream {
                guard !Task.isCancelled else { return }
                await self?.handleSessionExpired()
            }
        }
    }

    deinit {
        sessionExpiryTask?.cancel()
    }

    public func handleSessionExpired() async {
        guard sessionStore.session.isAuthenticated else { return }
        await logout()
    }

    public func logout() async {
        await authRepository.logout()
        await studentRepository.clearPersistentCache()
        homeLaunchGate.reset()
        sessionStore.clear()
        HomeWidgetRefresh.publishSignedOut()
    }
}
