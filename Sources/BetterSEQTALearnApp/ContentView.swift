import CoreCommon
import CoreDesign
import CoreSession
import Domain
import FeatureAuth
import SwiftUI

public struct ContentView: View {
    @ObservedObject private var sessionStore: LearnSessionStore
    @StateObject private var dependencies: LearnAppDependencies
    @State private var showOnboarding = !UserDefaults.standard.bool(forKey: "learn.onboardingComplete")
    @State private var isLoggingIn = false
    @State private var authError: String?
    @State private var pendingShellRoute: LearnShellDeeplinkRoute?

    public init(sessionStore: LearnSessionStore) {
        self.sessionStore = sessionStore
        _dependencies = StateObject(wrappedValue: LearnAppDependencies(sessionStore: sessionStore))
    }

    public var body: some View {
        Group {
            if sessionStore.session.isAuthenticated {
                MainShell(dependencies: dependencies, pendingShellRoute: $pendingShellRoute)
            } else {
                unauthenticatedFlow
            }
        }
        .onChange(of: sessionStore.session.isAuthenticated) { _, isAuthenticated in
            if !isAuthenticated {
                dependencies.homeLaunchGate.reset()
            }
        }
        .onOpenURL { url in
            Task { await handleDeeplink(url.absoluteString) }
        }
        .onReceive(NotificationCenter.default.publisher(for: LearnSessionExpiryNotifier.notification)) { _ in
            authError = "Session expired. Please sign in again."
        }
        .preferredColorScheme(.dark)
    }

    private var unauthenticatedFlow: some View {
        ZStack {
            LearnScreenBackground()
                .ignoresSafeArea()
            if showOnboarding {
                LearnOnboardingStubView {
                    UserDefaults.standard.set(true, forKey: "learn.onboardingComplete")
                    showOnboarding = false
                }
            } else {
                LearnLoginView(
                    isLoggingIn: isLoggingIn,
                    errorMessage: authError,
                    onDeeplink: { link in Task { await handleDeeplink(link) } },
                    onCredentialsLogin: { base, user, pass in
                        Task { await handleCredentials(base: base, username: user, password: pass) }
                    },
                    onWebSessionLogin: { base, jsession in
                        Task { await handleWebSession(base: base, jsession: jsession) }
                    },
                    onClearError: { authError = nil }
                )
            }
        }
    }

    @MainActor
    private func handleDeeplink(_ link: String) async {
        let trimmed = link.trimmingCharacters(in: .whitespacesAndNewlines)
        if !LearnShellDeeplinkRouter.isAuthDeeplink(trimmed),
           let route = LearnShellDeeplinkRouter.parse(trimmed) {
            pendingShellRoute = route
            if sessionStore.session.isAuthenticated {
                return
            }
            authError = nil
            return
        }

        isLoggingIn = true
        defer { isLoggingIn = false }
        let auth = dependencies.authRepository
        let result: AppResult<SessionData>
        if trimmed.contains("connect/") {
            result = await auth.loginWithConnect(deeplink: trimmed)
        } else {
            result = await auth.loginWithQr(deeplink: trimmed)
        }
        switch result {
        case .success:
            authError = nil
            showOnboarding = false
        case let .failure(error):
            authError = authMessage(error)
        }
    }

    @MainActor
    private func handleCredentials(base: String, username: String, password: String) async {
        isLoggingIn = true
        defer { isLoggingIn = false }
        let result = await dependencies.authRepository.loginWithCredentials(
            baseUrl: base,
            username: username,
            password: password
        )
        switch result {
        case .success:
            authError = nil
            showOnboarding = false
        case let .failure(error):
            authError = authMessage(error)
        }
    }

    @MainActor
    private func handleWebSession(base: String, jsession: String) async {
        isLoggingIn = true
        defer { isLoggingIn = false }
        let result = await dependencies.authRepository.loginWithWebSession(
            baseUrl: base,
            jsessionId: jsession
        )
        switch result {
        case .success:
            authError = nil
            showOnboarding = false
        case let .failure(error):
            authError = authMessage(error)
        }
    }

    private func authMessage(_ error: AppError) -> String {
        switch error {
        case let .auth(message): message
        case let .network(message): message
        case .sessionExpired: "Session expired"
        case let .unknown(message): message
        }
    }
}
