import CoreCommon
import CoreNetworking
import CoreSession
import Domain
import Foundation

@MainActor
public final class AuthRepositoryLive: AuthRepository {
    private let sessionStore: LearnSessionStore

    public init(sessionStore: LearnSessionStore) {
        self.sessionStore = sessionStore
    }

    public func currentSession() -> SessionData {
        sessionStore.session
    }

    public func logout() async {
        sessionStore.clear()
    }

    public func validateHeartbeat() async -> AppResult<Void> {
        guard let learnSession = sessionStore.learnSession else {
            return .failure(.auth(message: "Not logged in"))
        }
        do {
            _ = try await SeqtaStudentClient(session: learnSession).heartbeat()
            return .success(())
        } catch SeqtaStudentTransportError.sessionExpired {
            LearnSessionExpiryNotifier.post()
            return .failure(.sessionExpired)
        } catch let error as SeqtaStudentTransportError {
            switch error {
            case .sessionExpired:
                LearnSessionExpiryNotifier.post()
                return .failure(.sessionExpired)
            case let .httpStatus(code):
                return .failure(.network(message: "HTTP \(code)"))
            case .invalidResponse:
                return .failure(.network(message: "Invalid response"))
            }
        } catch {
            return .failure(.network(message: error.localizedDescription))
        }
    }

    public func loginWithQr(deeplink: String) async -> AppResult<SessionData> {
        do {
            guard let payload = AuthDeeplinkParser.parseSsoDeeplink(deeplink) else {
                return .failure(.auth(message: "Invalid QR deeplink"))
            }
            guard AuthJwtValidator.validate(token: payload.t) != nil else {
                return .failure(.auth(message: "QR code expired"))
            }

            let baseUrl = AuthURLHelpers.normalizeBaseUrl(payload.u)
            let token = payload.t

            var lastCookie: String?
            lastCookie = try await AuthLoginTransport.postJSON(
                url: "\(baseUrl)/seqta/student/login",
                body: #"{"token":"\#(escapeJSON(token))"}"#,
                jsessionId: token,
                bearer: token,
                userNumber: payload.n
            )

            lastCookie = try await AuthLoginTransport.postJSON(
                url: "\(baseUrl)/seqta/student/login",
                body: #"{"jwt":"\#(escapeJSON(token))"}"#,
                jsessionId: token,
                bearer: token,
                userNumber: payload.n
            )

            let jsessionId = AuthURLHelpers.parseSetCookie(lastCookie) ?? token

            _ = try await AuthLoginTransport.postJSON(
                url: "\(baseUrl)/seqta/student/heartbeat",
                body: #"{"heartbeat":true}"#,
                jsessionId: jsessionId,
                bearer: jsessionId.hasPrefix("eyJ") ? jsessionId : nil
            )

            return await saveSession(
                baseUrl: baseUrl,
                jsessionId: jsessionId,
                username: nil
            )
        } catch {
            return .failure(.auth(message: error.localizedDescription))
        }
    }

    public func loginWithConnect(deeplink: String) async -> AppResult<SessionData> {
        do {
            guard let payload = AuthDeeplinkParser.parseConnectDeeplink(deeplink) else {
                return .failure(.auth(message: "Invalid connect deeplink"))
            }
            let baseUrl = AuthURLHelpers.normalizeBaseUrl(payload.u)
            let jsessionId = payload.s

            _ = try await AuthLoginTransport.postJSON(
                url: "\(baseUrl)/seqta/student/heartbeat",
                body: #"{"heartbeat":true}"#,
                jsessionId: jsessionId
            )

            return await saveSession(baseUrl: baseUrl, jsessionId: jsessionId, username: nil)
        } catch {
            return .failure(.auth(message: error.localizedDescription))
        }
    }

    public func loginWithCredentials(
        baseUrl: String,
        username: String,
        password: String
    ) async -> AppResult<SessionData> {
        do {
            let normalized = AuthURLHelpers.normalizeBaseUrl(baseUrl)
            let body = """
            {"username":"\(escapeJSON(username))","password":"\(escapeJSON(password))","mode":"normal","query":null}
            """
            let (_, response) = try await AuthLoginTransport.postJSONWithResponse(
                url: "\(normalized)/seqta/student/login",
                body: body
            )
            guard let jsessionId = AuthURLHelpers.parseSetCookie(response.value(forHTTPHeaderField: "Set-Cookie")) else {
                return .failure(.auth(message: "Missing JSESSIONID"))
            }

            _ = try await AuthLoginTransport.postJSON(
                url: "\(normalized)/seqta/student/heartbeat",
                body: #"{"heartbeat":true}"#,
                jsessionId: jsessionId
            )

            return await saveSession(baseUrl: normalized, jsessionId: jsessionId, username: username)
        } catch {
            return .failure(.auth(message: error.localizedDescription))
        }
    }

    public func loginWithWebSession(baseUrl: String, jsessionId: String) async -> AppResult<SessionData> {
        let trimmed = jsessionId.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return .failure(.auth(message: "Missing session cookie"))
        }
        do {
            let normalized = AuthURLHelpers.normalizeBaseUrl(baseUrl)
            _ = try await AuthLoginTransport.postJSON(
                url: "\(normalized)/seqta/student/heartbeat",
                body: #"{"heartbeat":true}"#,
                jsessionId: trimmed,
                bearer: trimmed.hasPrefix("eyJ") ? trimmed : nil
            )
            return await saveSession(baseUrl: normalized, jsessionId: trimmed, username: nil)
        } catch {
            return .failure(.auth(message: error.localizedDescription))
        }
    }

    private func saveSession(
        baseUrl: String,
        jsessionId: String,
        username: String?
    ) async -> AppResult<SessionData> {
        let profile = await fetchUserProfile(baseUrl: baseUrl, jsessionId: jsessionId, fallbackUserName: username)
        let session = SessionData(
            baseUrl: baseUrl,
            jsessionId: jsessionId,
            storedUsername: username,
            storedPassword: nil,
            userId: profile?.id ?? extractUserIdFromJwt(jsessionId),
            displayName: profile?.displayName ?? profile?.userDesc
        )
        sessionStore.updateSession(session)
        sessionStore.persistToKeychain()
        return .success(session)
    }

    private func fetchUserProfile(
        baseUrl: String,
        jsessionId: String,
        fallbackUserName: String?
    ) async -> UserProfile? {
        do {
            let (data, _) = try await AuthLoginTransport.postJSONWithResponse(
                url: "\(baseUrl)/seqta/student/login",
                body: "{}",
                jsessionId: jsessionId,
                bearer: jsessionId.hasPrefix("eyJ") ? jsessionId : nil
            )
            let payload = try JSONObjectHelpers.seqtaPayload(from: data)
            return SeqtaResponseParsers.parseLoginProfile(payload: payload, fallbackUserName: fallbackUserName)
        } catch {
            return nil
        }
    }

    private func escapeJSON(_ value: String) -> String {
        var escaped = value
        escaped = escaped.replacingOccurrences(of: "\\", with: "\\\\")
        escaped = escaped.replacingOccurrences(of: "\"", with: "\\\"")
        escaped = escaped.replacingOccurrences(of: "\n", with: "\\n")
        return escaped
    }
}
