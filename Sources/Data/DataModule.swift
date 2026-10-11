import CoreSession
import Domain
import Foundation

public enum DataModule {
    public static let fixtureBundleDescription = "JSON fixtures under Tests/Fixtures/ (bundled in DataTests)."

    @MainActor
    public static func makeAuthRepository(sessionStore: LearnSessionStore) -> AuthRepository {
        AuthRepositoryLive(sessionStore: sessionStore)
    }

    public static func makeStudentRepository(sessionProvider: @escaping @Sendable () -> SessionData) -> StudentRepository {
        StudentRepositoryLive(sessionProvider: sessionProvider)
    }

    @MainActor
    public static func makeCalendarSyncRepository(studentRepository: StudentRepository) -> CalendarSyncRepository {
        CalendarSyncRepositoryLive(studentRepository: studentRepository)
    }
}
