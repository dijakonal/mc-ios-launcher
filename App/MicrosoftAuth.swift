//
//  MicrosoftAuth.swift
//  MC iOS Launcher
//
//  Microsoft OAuth2 authentication for Minecraft account
//  Flow: OAuth2 -> Xbox Live -> XSTS -> Minecraft
//

import Foundation
import AuthenticationServices

class MicrosoftAuth: NSObject {
    
    // Azure AD OAuth2 configuration for Minecraft
    // Using the official Minecraft launcher client ID
    private let clientId = "00000000-0000-0000-0000-000000000000" // Replace with actual
    private let redirectUri = "msauth.com.mcioslauncher.app://auth/"
    private let scope = "service::user.auth.xboxlive.com::MBI_SSL"
    
    // OAuth2 endpoints
    private let authorizeURL = "https://login.microsoftonline.com/consumers/oauth2/v2.0/authorize"
    private let tokenURL = "https://login.microsoftonline.com/consumers/oauth2/v2.0/token"
    
    // Xbox Live endpoints
    private let xboxLiveAuthURL = "https://user.auth.xboxlive.com/user/authenticate"
    private let xstsURL = "https://xsts.auth.xboxlive.com/xsts/authorize"
    
    // Minecraft endpoints
    private let mcProfileURL = "https://api.minecraftservices.com/authentication/login_with_xbox"
    private let mcEntitlementsURL = "https://api.minecraftservices.com/entitlements/mcstore"
    private let mcProfileDetailsURL = "https://api.minecraftservices.com/minecraft/profile"
    
    private var authSession: ASWebAuthenticationSession?
    private var continuation: CheckedContinuation<MicrosoftAccount, Error>?
    
    func authenticate() async throws -> MicrosoftAccount {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            // Start OAuth2 flow
            guard let authURL = buildAuthorizeURL() else {
                continuation.resume(throwing: AuthError.invalidURL)
                return
            }
            
            authSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: "msauth"
            ) { callbackURL, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let callbackURL = callbackURL else {
                    continuation.resume(throwing: AuthError.noCallback)
                    return
                }
                
                Task {
                    do {
                        let account = try await self.handleCallback(callbackURL)
                        continuation.resume(returning: account)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            authSession?.prefersEphemeralWebBrowserSession = false
            authSession?.start()
        }
    }
    
    private func buildAuthorizeURL() -> URL? {
        var components = URLComponents(string: authorizeURL)
        components?.queryItems = [
            URLQueryItem(name: "client_id", value: clientId),
            URLQueryItem(name: "redirect_uri", value: redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: "XboxLive.signin%20offline_access"),
            URLQueryItem(name: "prompt", value: "select_account"),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        return components?.url
    }
    
    private func handleCallback(_ url: URL) async throws -> MicrosoftAccount {
        guard let components = URLComponents(url: url, resolvingAgainstBaseURL: true),
              let code = components.queryItems?.first(where: { $0.name == "code" })?.value else {
            throw AuthError.noAuthCode
        }
        
        // Exchange code for token
        let oauthToken = try await exchangeCodeForToken(code: code)
        
        // Get Xbox Live token
        let xboxToken = try await authenticateXboxLive(oauthToken: oauthToken)
        
        // Get XSTS token
        let xstsToken = try await authorizeXSTS(xboxToken: xboxToken)
        
        // Get Minecraft token
        let mcToken = try await loginWithXbox(xstsToken: xstsToken)
        
        // Get profile
        let profile = try await getMinecraftProfile(mcToken: mcToken)
        
        return MicrosoftAccount(
            xboxLiveToken: xboxToken.token,
            xstsToken: xstsToken.token,
            mcToken: mcToken,
            uuid: profile.id,
            username: profile.name,
            expiresAt: Date().addingTimeInterval(3600) // 1 hour
        )
    }
    
    private func exchangeCodeForToken(code: String) async throws -> OAuthToken {
        var request = URLRequest(url: URL(string: tokenURL)!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        
        let body = [
            "client_id": clientId,
            "code": code,
            "grant_type": "authorization_code",
            "redirect_uri": redirectUri,
            "scope": "XboxLive.signin offline_access"
        ].map { "\($0.key)=\($0.value.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")" }
        .joined(separator: "&")
        
        request.httpBody = body.data(using: .utf8)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.tokenExchangeFailed
        }
        
        return try JSONDecoder().decode(OAuthToken.self, from: data)
    }
    
    private func authenticateXboxLive(oauthToken: OAuthToken) async throws -> XboxToken {
        var request = URLRequest(url: URL(string: xboxLiveAuthURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "Properties": [
                "AuthMethod": "RPS",
                "SiteName": "user.auth.xboxlive.com",
                "RpsTicket": "d=\(oauthToken.accessToken)"
            ],
            "RelyingParty": "http://auth.xboxlive.com",
            "TokenType": "JWT"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.xboxAuthFailed
        }
        
        return try JSONDecoder().decode(XboxToken.self, from: data)
    }
    
    private func authorizeXSTS(xboxToken: XboxToken) async throws -> XSTSToken {
        var request = URLRequest(url: URL(string: xstsURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "Properties": [
                "SandboxId": "RETAIL",
                "UserTokens": [xboxToken.token]
            ],
            "RelyingParty": "rp://api.minecraftservices.com/",
            "TokenType": "JWT"
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.xstsAuthFailed
        }
        
        return try JSONDecoder().decode(XSTSToken.self, from: data)
    }
    
    private func loginWithXbox(xstsToken: XSTSToken) async throws -> String {
        var request = URLRequest(url: URL(string: mcProfileURL)!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "identityToken": xstsToken.token
        ]
        
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.mcAuthFailed
        }
        
        let result = try JSONDecoder().decode(MinecraftAuthResult.self, from: data)
        return result.accessToken
    }
    
    private func getMinecraftProfile(mcToken: String) async throws -> MinecraftProfile {
        var request = URLRequest(url: URL(string: mcProfileDetailsURL)!)
        request.setValue("Bearer \(mcToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, http.statusCode == 200 else {
            throw AuthError.profileFetchFailed
        }
        
        return try JSONDecoder().decode(MinecraftProfile.self, from: data)
    }
    
    // MARK: - Token Refresh
    
    func refreshToken(_ account: MicrosoftAccount) async throws -> MicrosoftAccount {
        // Implement token refresh using the refresh_token from OAuth
        // For now, just re-authenticate
        return try await authenticate()
    }
}

// MARK: - Models

struct OAuthToken: Codable {
    let accessToken: String
    let refreshToken: String
    let expiresIn: Int
    let scope: String
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case scope
    }
}

struct XboxToken: Codable {
    let token: String
    let displayClaims: DisplayClaims
    
    struct DisplayClaims: Codable {
        let xui: [XUIDisplayClaim]
        
        struct XUIDisplayClaim: Codable {
            let uhs: String // User Hash
        }
    }
}

struct XSTSToken: Codable {
    let token: String
    let displayClaims: XboxToken.DisplayClaims
}

struct MinecraftAuthResult: Codable {
    let accessToken: String
    let tokenType: String
    let expiresAt: Int
    
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresAt = "expires_in"
    }
}

struct MinecraftProfile: Codable {
    let id: String
    let name: String
    let skins: [Skin]
    let capes: [Cape]
    
    struct Skin: Codable {
        let id: String
        let state: String
        let url: String?
        let variant: String
    }
    
    struct Cape: Codable {
        let id: String
        let url: String?
    }
}

// MARK: - Errors

enum AuthError: LocalizedError {
    case invalidURL
    case noCallback
    case noAuthCode
    case tokenExchangeFailed
    case xboxAuthFailed
    case xstsAuthFailed
    case mcAuthFailed
    case profileFetchFailed
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid authentication URL"
        case .noCallback: return "No callback received from authentication"
        case .noAuthCode: return "No authorization code received"
        case .tokenExchangeFailed: return "Failed to exchange authorization code"
        case .xboxAuthFailed: return "Xbox Live authentication failed"
        case .xstsAuthFailed: return "XSTS authentication failed"
        case .mcAuthFailed: return "Minecraft authentication failed"
        case .profileFetchFailed: return "Failed to fetch Minecraft profile"
        }
    }
}
