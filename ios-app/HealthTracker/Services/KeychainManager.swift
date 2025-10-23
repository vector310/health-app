//
//  KeychainManager.swift
//  HealthTracker
//
//  Secure storage for API credentials using Keychain
//

import Foundation
import Security

class KeychainManager {

    static let shared = KeychainManager()

    private init() {}

    // MARK: - Keys

    enum Key: String {
        case apiKey = "com.healthtracker.apiKey"
        case serverURL = "com.healthtracker.serverURL"
    }

    // MARK: - Save

    func save(_ value: String, for key: Key) -> Bool {
        guard let data = value.data(using: .utf8) else { return false }

        // Delete any existing item
        delete(key)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked
        ]

        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }

    // MARK: - Retrieve

    func get(_ key: Key) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }

        return value
    }

    // MARK: - Delete

    @discardableResult
    func delete(_ key: Key) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key.rawValue
        ]

        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }

    // MARK: - Clear All

    func clearAll() -> Bool {
        var success = true
        for key in [Key.apiKey, Key.serverURL] {
            success = delete(key) && success
        }
        return success
    }

    // MARK: - Convenience

    var apiKey: String? {
        get { get(.apiKey) }
        set {
            if let value = newValue {
                save(value, for: .apiKey)
            } else {
                delete(.apiKey)
            }
        }
    }

    var serverURL: String? {
        get { get(.serverURL) }
        set {
            if let value = newValue {
                save(value, for: .serverURL)
            } else {
                delete(.serverURL)
            }
        }
    }

    var isConfigured: Bool {
        apiKey != nil && serverURL != nil
    }
}
