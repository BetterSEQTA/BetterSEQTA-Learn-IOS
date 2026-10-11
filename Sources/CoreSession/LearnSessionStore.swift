import Combine
import Domain
import Foundation

/// Observable session holder with Keychain persistence.
@MainActor
public final class LearnSessionStore: ObservableObject {
    private static let encoder = JSONEncoder()
    private static let decoder = JSONDecoder()
    private let sessionLock = NSLock()
    private nonisolated(unsafe) var sendableSessionSnapshot: SessionData

    @Published public private(set) var session: SessionData

    public init(session: SessionData? = nil) {
        let initial: SessionData
        if let session {
            initial = session
        } else if let loaded = Self.loadFromKeychain() {
            initial = loaded
        } else {
            initial = SessionData()
        }
        sendableSessionSnapshot = initial
        self.session = initial
    }

    /// Thread-safe snapshot for `@Sendable` repository session providers.
    public nonisolated func currentSession() -> SessionData {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return sendableSessionSnapshot
    }

    public func updateSession(_ session: SessionData) {
        self.session = session
        syncSendableSnapshot()
    }

    private func syncSendableSnapshot() {
        sessionLock.lock()
        sendableSessionSnapshot = session
        sessionLock.unlock()
    }

    public func persistToKeychain() {
        guard session.isAuthenticated else {
            try? LearnKeychain.deleteSession()
            return
        }
        do {
            let data = try Self.encoder.encode(session)
            guard let json = String(data: data, encoding: .utf8) else { return }
            try LearnKeychain.saveSessionJSON(json)
        } catch {
            // Keychain failures are non-fatal; session remains in memory.
        }
    }

    public func clear() {
        session = session.cleared()
        syncSendableSnapshot()
        try? LearnKeychain.deleteSession()
    }

    public var learnSession: LearnSession? {
        LearnSession(sessionData: session)
    }

    private static func loadFromKeychain() -> SessionData? {
        guard let json = try? LearnKeychain.loadSessionJSON(),
              let data = json.data(using: .utf8),
              let decoded = try? decoder.decode(SessionData.self, from: data) else {
            return nil
        }
        return decoded
    }
}
