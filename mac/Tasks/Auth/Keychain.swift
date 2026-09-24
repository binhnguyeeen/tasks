import Foundation
import Security

nonisolated struct Keychain: Sendable {
    struct Credentials: Codable, Sendable {
        var refreshToken: String
        var email: String?
    }

    var service = "com.binhnguyen.tasks"
    var account = "google"

    func load() -> Credentials? {
        var query = baseQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: AnyObject?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data
        else { return nil }
        return try? JSONDecoder().decode(Credentials.self, from: data)
    }

    func save(_ credentials: Credentials) {
        guard let data = try? JSONEncoder().encode(credentials) else { return }
        let update = [kSecValueData as String: data] as CFDictionary
        if SecItemUpdate(baseQuery as CFDictionary, update) == errSecItemNotFound {
            var query = baseQuery
            query[kSecValueData as String] = data
            query[kSecAttrLabel as String] = "Tasks (Google account)"
            SecItemAdd(query as CFDictionary, nil)
        }
    }

    func delete() {
        SecItemDelete(baseQuery as CFDictionary)
    }

    private var baseQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
    }
}
