import AuthenticationServices
import Foundation
import Observation
import SwiftUI

@Observable
final class GoogleAuth {
    enum AuthError: LocalizedError {
        case notConfigured
        case missingPermission
        case failed
        case signedOut

        var errorDescription: String? {
            switch self {
            case .notConfigured: "Add your Google client ID to mac/Config.xcconfig, then rebuild."
            case .missingPermission: "Tasks needs permission to see and edit your tasks. Sign in again and leave it ticked."
            case .failed: "Couldn’t sign in. Check your connection and try again."
            case .signedOut: "You’re signed out."
            }
        }
    }

    private(set) var isSignedIn: Bool
    private(set) var email: String?
    let clientID: String?

    private let keychain: Keychain
    private var refreshToken: String?
    private var accessToken: String?
    private var accessTokenExpiry = Date.distantPast
    private var refreshTask: Task<String, Error>?

    private static let tasksScope = "https://www.googleapis.com/auth/tasks"
    private static let clientSuffix = ".apps.googleusercontent.com"

    init(keychain: Keychain = Keychain(), bundle: Bundle = .main) {
        self.keychain = keychain
        clientID = Self.clientID(in: bundle)
        let saved = keychain.load()
        refreshToken = saved?.refreshToken
        email = saved?.email
        isSignedIn = saved != nil
    }

    var isConfigured: Bool { clientID != nil }

    #if DEBUG
    func useSampleAccount() {
        email = "sample@example.com"
        isSignedIn = true
    }
    #endif

    func signIn(with session: WebAuthenticationSession) async throws {
        guard let clientID else { throw AuthError.notConfigured }
        let scheme = "com.googleusercontent.apps." + clientID.dropLast(Self.clientSuffix.count)
        let redirectURI = scheme + ":/oauth2redirect"
        let verifier = PKCE.randomString()
        let state = PKCE.randomString()

        var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "openid email \(Self.tasksScope)"),
            URLQueryItem(name: "code_challenge", value: PKCE.challenge(for: verifier)),
            URLQueryItem(name: "code_challenge_method", value: "S256"),
            URLQueryItem(name: "state", value: state),
        ]
        guard let url = components?.url else { throw AuthError.failed }

        let callback = try await session.authenticate(using: url, callbackURLScheme: scheme)
        let items = URLComponents(url: callback, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let value = { (name: String) in items.first { $0.name == name }?.value }
        if value("error") == "access_denied" { throw AuthError.missingPermission }
        guard value("state") == state, let code = value("code") else { throw AuthError.failed }

        let tokens = try await tokenRequest([
            "grant_type": "authorization_code",
            "client_id": clientID,
            "code": code,
            "code_verifier": verifier,
            "redirect_uri": redirectURI,
        ])
        guard let scopes = tokens.scope, scopes.split(separator: " ").contains(Substring(Self.tasksScope)) else {
            throw AuthError.missingPermission
        }
        guard let refresh = tokens.refreshToken else { throw AuthError.failed }

        let signedInEmail = tokens.idToken.flatMap(Self.email(fromIDToken:))
        keychain.save(Keychain.Credentials(refreshToken: refresh, email: signedInEmail))
        refreshToken = refresh
        accessToken = tokens.accessToken
        accessTokenExpiry = Date.now.addingTimeInterval(TimeInterval(tokens.expiresIn ?? 3600))
        email = signedInEmail
        isSignedIn = true
    }

    func signOut() async {
        let token = refreshToken
        clearSession()
        guard let token, var request = Self.formRequest("https://oauth2.googleapis.com/revoke", ["token": token]) else { return }
        request.timeoutInterval = 10
        _ = try? await TasksAPI.uncachedSession.data(for: request)
    }

    func accessToken(forceRefresh: Bool) async throws -> String {
        if !forceRefresh, let accessToken, accessTokenExpiry.timeIntervalSinceNow > 60 {
            return accessToken
        }
        if let refreshTask {
            return try await refreshTask.value
        }
        let task = Task { try await self.refreshAccessToken() }
        refreshTask = task
        defer { refreshTask = nil }
        return try await task.value
    }

    private func refreshAccessToken() async throws -> String {
        guard let clientID, let refreshToken else { throw AuthError.signedOut }
        do {
            let tokens = try await tokenRequest([
                "grant_type": "refresh_token",
                "client_id": clientID,
                "refresh_token": refreshToken,
            ])
            accessToken = tokens.accessToken
            accessTokenExpiry = Date.now.addingTimeInterval(TimeInterval(tokens.expiresIn ?? 3600))
            return tokens.accessToken
        } catch TokenError.invalidGrant {
            clearSession()
            throw AuthError.signedOut
        }
    }

    private func clearSession() {
        keychain.delete()
        refreshToken = nil
        accessToken = nil
        accessTokenExpiry = .distantPast
        email = nil
        isSignedIn = false
    }

    private enum TokenError: Error {
        case invalidGrant
    }

    private struct TokenResponse: Decodable {
        var accessToken: String
        var expiresIn: Int?
        var refreshToken: String?
        var scope: String?
        var idToken: String?
    }

    private struct TokenErrorResponse: Decodable {
        var error: String?
    }

    private func tokenRequest(_ form: [String: String]) async throws -> TokenResponse {
        guard let request = Self.formRequest("https://oauth2.googleapis.com/token", form) else { throw AuthError.failed }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await TasksAPI.uncachedSession.data(for: request)
        } catch let error as URLError where error.isConnectivityProblem {
            throw TasksAPIError.offline
        }
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        guard (response as? HTTPURLResponse)?.statusCode == 200 else {
            if (try? decoder.decode(TokenErrorResponse.self, from: data))?.error == "invalid_grant" {
                throw TokenError.invalidGrant
            }
            throw AuthError.failed
        }
        return try decoder.decode(TokenResponse.self, from: data)
    }

    private static func formRequest(_ address: String, _ form: [String: String]) -> URLRequest? {
        guard let url = URL(string: address) else { return nil }
        var allowed = CharacterSet.alphanumerics
        allowed.insert(charactersIn: "-._~")
        let body = form
            .map { key, value in "\(key)=\(value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value)" }
            .joined(separator: "&")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = Data(body.utf8)
        return request
    }

    private static func clientID(in bundle: Bundle) -> String? {
        guard let id = bundle.object(forInfoDictionaryKey: "GoogleClientID") as? String,
              id.hasSuffix(clientSuffix), id.count > clientSuffix.count, !id.hasPrefix("YOUR_")
        else { return nil }
        return id
    }

    nonisolated static func email(fromIDToken token: String) -> String? {
        let parts = token.split(separator: ".")
        guard parts.count >= 2,
              let payload = Data(base64URLEncoded: String(parts[1])),
              let claims = try? JSONSerialization.jsonObject(with: payload) as? [String: Any]
        else { return nil }
        return claims["email"] as? String
    }
}
