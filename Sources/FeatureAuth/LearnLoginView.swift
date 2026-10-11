import CoreDesign
import SwiftUI

public struct LearnLoginView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var loginViewModel = LoginViewModel()

    private let isLoggingIn: Bool
    private let errorMessage: String?
    private let onDeeplink: (String) -> Void
    private let onCredentialsLogin: (String, String, String) -> Void
    private let onWebSessionLogin: (String, String) -> Void
    private let onClearError: () -> Void

    @State private var selectedTab: LearnLoginMethod = .qr
    @State private var baseUrl = ""
    @State private var webBaseUrl = ""
    @State private var username = ""
    @State private var password = ""
    @State private var pastedLink = ""
    @State private var showWebLogin = false
    @State private var alertMessage: String?

    public init(
        isLoggingIn: Bool,
        errorMessage: String?,
        onDeeplink: @escaping (String) -> Void,
        onCredentialsLogin: @escaping (String, String, String) -> Void,
        onWebSessionLogin: @escaping (String, String) -> Void,
        onClearError: @escaping () -> Void
    ) {
        self.isLoggingIn = isLoggingIn
        self.errorMessage = errorMessage
        self.onDeeplink = onDeeplink
        self.onCredentialsLogin = onCredentialsLogin
        self.onWebSessionLogin = onWebSessionLogin
        self.onClearError = onClearError
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: LearnTheme.Spacing.lg) {
                if isLoggingIn {
                    VStack(spacing: 12) {
                        FluidLoadingBarView(progress: 0.65, phaseText: "Connecting to SEQTA…")
                        LearnSkeletonView(preset: .settingsForm)
                            .frame(height: 160)
                            .allowsHitTesting(false)
                    }
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                VStack(spacing: LearnTheme.Spacing.sm) {
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 48))
                        .foregroundStyle(LearnTheme.Colors.accent)
                    Text("BetterSEQTA Learn")
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(LearnTheme.Colors.primaryText)
                    Text("Sign in with your school SEQTA account")
                        .font(.subheadline)
                        .foregroundStyle(LearnTheme.Colors.secondaryText)
                        .multilineTextAlignment(.center)
                }

                LearnUnderlineSegmentBar(
                    items: LearnLoginMethod.allCases.map { ($0, $0.title) },
                    selection: selectedTab,
                    density: .regular,
                    style: .fluid
                ) { selectedTab = $0 }
                .padding(.vertical, 4)

                switch selectedTab {
                case .qr:
                    QRScannerEntryView(
                        pastedLink: $pastedLink,
                        isLoggingIn: isLoggingIn,
                        onSubmitLink: submitPastedLink,
                        onScannedLink: { link in
                            if authDeeplinkError(link) == nil {
                                onDeeplink(link)
                            } else {
                                alertMessage = "Unrecognized QR code. Paste a SEQTA login link instead."
                            }
                        }
                    )
                case .credentials:
                    credentialsPanel
                case .schoolWeb:
                    schoolWebPanel
                }
            }
            .padding(LearnTheme.Spacing.md)
        }
        .background { LearnScreenBackground() }
        .environment(\.learnMotionProfile, LearnMotionProfile.current(reduceMotion: reduceMotion))
        .onAppear {
            applyRememberedUrl()
        }
        .onChange(of: loginViewModel.rememberedSchoolUrl) { _, _ in
            applyRememberedUrl()
        }
        .onChange(of: errorMessage) { _, message in
            if let message, !message.isEmpty {
                alertMessage = message
                onClearError()
            }
        }
        .alert("Sign in", isPresented: Binding(
            get: { alertMessage != nil },
            set: { if !$0 { alertMessage = nil } }
        )) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            Text(alertMessage ?? "")
        }
        .sheet(isPresented: $showWebLogin) {
            LoginWebView(baseUrl: webBaseUrl) { url, jsession in
                loginViewModel.rememberSchoolUrl(url)
                onWebSessionLogin(url, jsession)
            }
        }
    }

    private var credentialsPanel: some View {
        VStack(alignment: .leading, spacing: LearnTheme.Spacing.md) {
            Text("Sign in with credentials")
                .font(.headline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            UrlEntryView(title: "School SEQTA URL", text: $baseUrl)
            UrlEntryView(title: "Username", placeholder: "student.username", text: $username)
            SecureField("Password", text: $password)
                .padding(LearnTheme.Spacing.md)
                .learnGlassInsetField()
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Button("Sign in") {
                let normalized = WebSessionCookieParser.normalizeSchoolBaseUrl(baseUrl.trimmingCharacters(in: .whitespacesAndNewlines))
                loginViewModel.rememberSchoolUrl(normalized)
                onCredentialsLogin(normalized, username.trimmingCharacters(in: .whitespacesAndNewlines), password)
            }
            .buttonStyle(LearnPrimaryButtonStyle())
            .disabled(baseUrl.isBlank || username.isBlank || password.isEmpty || isLoggingIn)
        }
    }

    private var schoolWebPanel: some View {
        VStack(alignment: .leading, spacing: LearnTheme.Spacing.md) {
            Text("Sign in via school website")
                .font(.headline)
                .foregroundStyle(LearnTheme.Colors.primaryText)
            Text("Opens your school SEQTA Learn page. After you sign in, we capture your session automatically.")
                .font(.footnote)
                .foregroundStyle(LearnTheme.Colors.secondaryText)
            UrlEntryView(title: "School SEQTA URL", text: $webBaseUrl)
            Button("Open school login") {
                let normalized = WebSessionCookieParser.normalizeSchoolBaseUrl(webBaseUrl.trimmingCharacters(in: .whitespacesAndNewlines))
                if normalized.isEmpty {
                    alertMessage = "Enter your school SEQTA URL first"
                } else {
                    loginViewModel.rememberSchoolUrl(normalized)
                    webBaseUrl = normalized
                    showWebLogin = true
                }
            }
            .buttonStyle(LearnPrimaryButtonStyle())
            .disabled(webBaseUrl.isBlank || isLoggingIn)
        }
    }

    private func submitPastedLink() {
        let trimmed = pastedLink.trimmingCharacters(in: .whitespacesAndNewlines)
        if let error = authDeeplinkError(trimmed) {
            alertMessage = error
        } else {
            onDeeplink(trimmed)
        }
    }

    private func applyRememberedUrl() {
        let remembered = loginViewModel.rememberedSchoolUrl
        guard !remembered.isEmpty else { return }
        if baseUrl.isEmpty { baseUrl = remembered }
        if webBaseUrl.isEmpty { webBaseUrl = remembered }
    }
}

private enum LearnLoginMethod: String, CaseIterable, Hashable {
    case qr
    case credentials
    case schoolWeb

    var title: String {
        switch self {
        case .qr: return "QR"
        case .credentials: return "Sign in"
        case .schoolWeb: return "Web"
        }
    }
}

private extension String {
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}
