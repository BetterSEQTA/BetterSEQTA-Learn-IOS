import Domain
import Foundation

/// Active SEQTA student session used for authenticated HTTP calls.
public struct LearnSession: Sendable, Equatable {
    public let baseURL: URL
    public let jsessionId: String

    public init(baseURL: URL, jsessionId: String) {
        self.baseURL = baseURL
        self.jsessionId = jsessionId
    }

    public init?(sessionData: SessionData) {
        let trimmedBase = sessionData.baseUrl.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedCookie = sessionData.jsessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedBase.isEmpty, !trimmedCookie.isEmpty else { return nil }
        guard let url = URL(string: trimmedBase.hasSuffix("/") ? String(trimmedBase.dropLast()) : trimmedBase)
            ?? URL(string: trimmedBase) else {
            return nil
        }
        self.baseURL = url
        self.jsessionId = trimmedCookie
    }
}
