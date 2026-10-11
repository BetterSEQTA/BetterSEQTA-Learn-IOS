import Foundation

@MainActor
public final class LoginPreferencesStore {
    private static let rememberedURLKey = "learn.rememberedSchoolUrl"

    public init() {}

    public var rememberedSchoolUrl: String {
        UserDefaults.standard.string(forKey: Self.rememberedURLKey) ?? ""
    }

    public func setRememberedSchoolUrl(_ url: String) {
        UserDefaults.standard.set(url, forKey: Self.rememberedURLKey)
    }
}
