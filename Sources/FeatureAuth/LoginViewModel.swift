import Foundation

@MainActor
public final class LoginViewModel: ObservableObject {
    private let preferences: LoginPreferencesStore

    @Published public private(set) var rememberedSchoolUrl: String

    public init(preferences: LoginPreferencesStore = LoginPreferencesStore()) {
        self.preferences = preferences
        self.rememberedSchoolUrl = preferences.rememberedSchoolUrl
    }

    public func rememberSchoolUrl(_ url: String) {
        let normalized = WebSessionCookieParser.normalizeSchoolBaseUrl(url)
        preferences.setRememberedSchoolUrl(normalized)
        rememberedSchoolUrl = normalized
    }
}
