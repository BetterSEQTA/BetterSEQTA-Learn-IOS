import Foundation

/// Persisted student session (mirrors Android `SessionData`).
public struct SessionData: Sendable, Equatable, Codable {
    public var baseUrl: String
    public var jsessionId: String
    public var storedUsername: String?
    public var storedPassword: String?
    public var userId: Int?
    public var displayName: String?

    public init(
        baseUrl: String = "",
        jsessionId: String = "",
        storedUsername: String? = nil,
        storedPassword: String? = nil,
        userId: Int? = nil,
        displayName: String? = nil
    ) {
        self.baseUrl = baseUrl
        self.jsessionId = jsessionId
        self.storedUsername = storedUsername
        self.storedPassword = storedPassword
        self.userId = userId
        self.displayName = displayName
    }

    public var isAuthenticated: Bool {
        !baseUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && !jsessionId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    public func withCredentials(username: String?, password: String?) -> SessionData {
        SessionData(
            baseUrl: baseUrl,
            jsessionId: jsessionId,
            storedUsername: username,
            storedPassword: password,
            userId: userId,
            displayName: displayName
        )
    }

    public func cleared() -> SessionData {
        SessionData()
    }
}
