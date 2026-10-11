import Foundation
import Security

public enum LearnKeychainError: Error, Sendable {
    case encodingFailed
    case saveFailed(OSStatus)
    case loadFailed(OSStatus)
    case deleteFailed(OSStatus)
}

/// Keychain storage for `SessionData` JSON (service scoped to Learn app).
public enum LearnKeychain {
    public static let serviceName = "org.betterseqta.learn.session"
    public static let sessionAccount = "session.v1"

    public static func saveSessionJSON(_ json: String) throws {
        guard let data = json.data(using: .utf8) else {
            throw LearnKeychainError.encodingFailed
        }
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionAccount,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly,
        ]
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw LearnKeychainError.saveFailed(status)
        }
    }

    public static func loadSessionJSON() throws -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else {
            if status == errSecItemNotFound { return nil }
            throw LearnKeychainError.loadFailed(status)
        }
        return String(data: data, encoding: .utf8)
    }

    public static func deleteSession() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: sessionAccount,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw LearnKeychainError.deleteFailed(status)
        }
    }
}
