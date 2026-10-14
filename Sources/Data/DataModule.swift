import CoreSession
import Domain
import Foundation

public enum DataModule {
    public static let fixtureBundleDescription = "JSON fixtures under Tests/Fixtures/ (bundled in DataTests)."

    private static let studentCacheDatabase = StudentLocalDatabase()

    @MainActor
    public static func makeAuthRepository(sessionStore: LearnSessionStore) -> AuthRepository {
        AuthRepositoryLive(sessionStore: sessionStore)
    }

    public static func makeStudentRepository(sessionProvider: @escaping @Sendable () -> SessionData) -> StudentRepository {
        let live = StudentRepositoryLive(sessionProvider: sessionProvider)
        return CachingStudentRepository(
            live: live,
            database: studentCacheDatabase,
            sessionProvider: sessionProvider
        )
    }

    @MainActor
    public static func makeCalendarSyncRepository(studentRepository: StudentRepository) -> CalendarSyncRepository {
        CalendarSyncRepositoryLive(studentRepository: studentRepository)
    }
}
