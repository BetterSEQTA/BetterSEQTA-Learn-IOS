import Domain
import Foundation
import Observation

@MainActor
@Observable
public final class LearnSettingsViewModel {
    public var displayName: String?
    public var schoolHost: String?
    public var isLoggingOut = false

    private let authRepository: AuthRepository

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        refreshFromSession()
    }

    public func refreshFromSession() {
        let session = authRepository.currentSession()
        displayName = session.displayName ?? session.storedUsername ?? "Signed in"
        if let url = URL(string: session.baseUrl), let host = url.host {
            schoolHost = host
        } else {
            schoolHost = session.baseUrl.isEmpty ? nil : session.baseUrl
        }
    }

    public func logout() async {
        isLoggingOut = true
        defer { isLoggingOut = false }
        await authRepository.logout()
        refreshFromSession()
    }
}
