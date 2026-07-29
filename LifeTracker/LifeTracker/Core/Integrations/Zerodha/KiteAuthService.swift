import Foundation
import UIKit
import AuthenticationServices
import CryptoKit

/// Drives the Kite Connect login flow: opens Zerodha's hosted login page in a
/// system web view (ASWebAuthenticationSession — your Zerodha password is
/// never seen by this app), catches the `lifetracker://kite-callback`
/// redirect Zerodha sends back with a `request_token`, and exchanges that for
/// an access token using your API secret. The access token is the only thing
/// kept afterwards, in Keychain; the request token is single-use and discarded.
///
/// Setup reminder (see README): in your Kite Connect app's developer console,
/// set the redirect URL to `lifetracker://kite-callback` exactly.
@MainActor
final class KiteAuthService: NSObject {
    static let shared = KiteAuthService()

    private var session: ASWebAuthenticationSession?

    func login(apiKey: String, apiSecret: String) async throws -> String {
        let requestToken = try await presentLogin(apiKey: apiKey)
        let accessToken = try await exchangeRequestToken(requestToken, apiKey: apiKey, apiSecret: apiSecret)
        KeychainService.set(accessToken, for: KiteCredentialKey.accessToken)
        return accessToken
    }

    private func presentLogin(apiKey: String) async throws -> String {
        guard var components = URLComponents(string: "https://kite.zerodha.com/connect/login") else {
            throw BrokerAdapterError.invalidResponse
        }
        components.queryItems = [
            URLQueryItem(name: "api_key", value: apiKey),
            URLQueryItem(name: "v", value: "3")
        ]
        guard let loginURL = components.url else { throw BrokerAdapterError.invalidResponse }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(url: loginURL, callbackURLScheme: "lifetracker") { callbackURL, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let callbackURL,
                      let token = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false)?
                        .queryItems?.first(where: { $0.name == "request_token" })?.value else {
                    continuation.resume(throwing: BrokerAdapterError.invalidResponse)
                    return
                }
                continuation.resume(returning: token)
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = true
            self.session = session
            session.start()
        }
    }

    private func exchangeRequestToken(_ requestToken: String, apiKey: String, apiSecret: String) async throws -> String {
        let checksumInput = apiKey + requestToken + apiSecret
        let checksum = SHA256.hash(data: Data(checksumInput.utf8)).map { String(format: "%02x", $0) }.joined()

        var request = URLRequest(url: URL(string: "https://api.kite.trade/session/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("3", forHTTPHeaderField: "X-Kite-Version")
        let body = "api_key=\(apiKey)&request_token=\(requestToken)&checksum=\(checksum)"
        request.httpBody = Data(body.utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
            throw BrokerAdapterError.api("Kite session exchange failed.")
        }
        struct SessionResponse: Decodable {
            struct KiteData: Decodable { let access_token: String }
            let data: KiteData
        }
        let decoded = try JSONDecoder().decode(SessionResponse.self, from: data)
        return decoded.data.access_token
    }
}

extension KiteAuthService: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow } ?? ASPresentationAnchor()
    }
}
