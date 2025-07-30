import Foundation
import AuthenticationServices
import CryptoKit
import GoogleSignIn

public enum AuthenticationMethod: String, CaseIterable {
    case apple = "apple"
    case google = "google"
    case email = "email"
    case phone = "phone"
    
    public var displayName: String {
        switch self {
        case .apple: return "Sign in with Apple"
        case .google: return "Sign in with Google"
        case .email: return "Email & Password"
        case .phone: return "Phone Number"
        }
    }
}

public enum AuthenticationError: Error, LocalizedError {
    case invalidCredentials
    case userNotFound
    case networkError
    case cancelled
    case unknownError
    case invalidEmail
    case weakPassword
    case invalidPhoneNumber
    case verificationFailed
    
    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Invalid credentials provided"
        case .userNotFound:
            return "User account not found"
        case .networkError:
            return "Network connection error"
        case .cancelled:
            return "Authentication cancelled"
        case .unknownError:
            return "An unknown error occurred"
        case .invalidEmail:
            return "Invalid email address"
        case .weakPassword:
            return "Password is too weak"
        case .invalidPhoneNumber:
            return "Invalid phone number"
        case .verificationFailed:
            return "Verification failed"
        }
    }
}

public struct AuthenticationCredentials {
    public let method: AuthenticationMethod
    public let identifier: String
    public let token: String?
    public let additionalData: [String: Any]
    
    public init(method: AuthenticationMethod, identifier: String, token: String? = nil, additionalData: [String: Any] = [:]) {
        self.method = method
        self.identifier = identifier
        self.token = token
        self.additionalData = additionalData
    }
}

public struct AuthenticatedUser {
    public let id: String
    public let email: String?
    public let displayName: String?
    public let phoneNumber: String?
    public let profileImageURL: URL?
    public let authenticationMethod: AuthenticationMethod
    public let isEmailVerified: Bool
    public let isPhoneVerified: Bool
    public let createdAt: Date
    public let lastLoginAt: Date
    
    public init(
        id: String,
        email: String? = nil,
        displayName: String? = nil,
        phoneNumber: String? = nil,
        profileImageURL: URL? = nil,
        authenticationMethod: AuthenticationMethod,
        isEmailVerified: Bool = false,
        isPhoneVerified: Bool = false,
        createdAt: Date = Date(),
        lastLoginAt: Date = Date()
    ) {
        self.id = id
        self.email = email
        self.displayName = displayName
        self.phoneNumber = phoneNumber
        self.profileImageURL = profileImageURL
        self.authenticationMethod = authenticationMethod
        self.isEmailVerified = isEmailVerified
        self.isPhoneVerified = isPhoneVerified
        self.createdAt = createdAt
        self.lastLoginAt = lastLoginAt
    }
}

@Observable
@MainActor
public final class AuthenticationService {
    public static let shared = AuthenticationService()
    
    public private(set) var currentUser: AuthenticatedUser?
    public private(set) var isAuthenticated = false
    public private(set) var isLoading = false
    public private(set) var lastError: AuthenticationError?
    
    private let keychainService = KeychainService.shared
    private let sessionKey = "auth_session"
    
    private init() {
        Task {
            await restoreSession()
        }
    }
    
    // MARK: - Public Authentication Methods
    
    public func signIn(with credentials: AuthenticationCredentials) async throws -> AuthenticatedUser {
        isLoading = true
        lastError = nil
        
        defer { isLoading = false }
        
        do {
            let user = try await performSignIn(with: credentials)
            currentUser = user
            isAuthenticated = true
            
            try await saveSession(user: user)
            
            return user
        } catch let error as AuthenticationError {
            lastError = error
            throw error
        } catch {
            let authError = AuthenticationError.unknownError
            lastError = authError
            throw authError
        }
    }
    
    public func signInWithApple(authorization: ASAuthorization) async throws -> AuthenticatedUser {
        guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            throw AuthenticationError.invalidCredentials
        }
        
        let userID = appleIDCredential.user
        let email = appleIDCredential.email
        let fullName = appleIDCredential.fullName
        
        var displayName: String?
        if let givenName = fullName?.givenName, let familyName = fullName?.familyName {
            displayName = "\(givenName) \(familyName)"
        }
        
        let credentials = AuthenticationCredentials(
            method: .apple,
            identifier: userID,
            token: String(data: appleIDCredential.identityToken ?? Data(), encoding: .utf8),
            additionalData: [
                "email": email ?? "",
                "displayName": displayName ?? ""
            ]
        )
        
        return try await signIn(with: credentials)
    }
    
    public func signInWithGoogle(result: GIDSignInResult) async throws -> AuthenticatedUser {
        let user = result.user
        let profile = user.profile
        
        let credentials = AuthenticationCredentials(
            method: .google,
            identifier: user.userID ?? "",
            token: user.idToken?.tokenString,
            additionalData: [
                "email": profile?.email ?? "",
                "displayName": profile?.name ?? "",
                "givenName": profile?.givenName ?? "",
                "familyName": profile?.familyName ?? "",
                "profileImageURL": profile?.imageURL(withDimension: 120)?.absoluteString ?? ""
            ]
        )
        
        return try await signIn(with: credentials)
    }
    
    public func signInWithEmail(_ email: String, password: String) async throws -> AuthenticatedUser {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        guard isValidPassword(password) else {
            throw AuthenticationError.weakPassword
        }
        
        let credentials = AuthenticationCredentials(
            method: .email,
            identifier: email,
            token: password
        )
        
        return try await signIn(with: credentials)
    }
    
    public func signUpWithEmail(_ email: String, password: String, displayName: String?) async throws -> AuthenticatedUser {
        guard isValidEmail(email) else {
            throw AuthenticationError.invalidEmail
        }
        
        guard isValidPassword(password) else {
            throw AuthenticationError.weakPassword
        }
        
        let credentials = AuthenticationCredentials(
            method: .email,
            identifier: email,
            token: password,
            additionalData: [
                "displayName": displayName ?? "",
                "isSignUp": true
            ]
        )
        
        return try await signIn(with: credentials)
    }
    
    public func signInWithPhone(_ phoneNumber: String, verificationCode: String) async throws -> AuthenticatedUser {
        guard isValidPhoneNumber(phoneNumber) else {
            throw AuthenticationError.invalidPhoneNumber
        }
        
        let credentials = AuthenticationCredentials(
            method: .phone,
            identifier: phoneNumber,
            token: verificationCode
        )
        
        return try await signIn(with: credentials)
    }
    
    public func sendPhoneVerification(to phoneNumber: String) async throws {
        guard isValidPhoneNumber(phoneNumber) else {
            throw AuthenticationError.invalidPhoneNumber
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // Simulate phone verification sending
        try await Task.sleep(for: .seconds(1))
        
        // In a real implementation, this would call a phone verification service
        print("Verification code sent to \(phoneNumber)")
    }
    
    public func signOut() async throws {
        isLoading = true
        defer { isLoading = false }
        
        try await clearSession()
        
        currentUser = nil
        isAuthenticated = false
        lastError = nil
    }
    
    public func deleteAccount() async throws {
        guard currentUser != nil else {
            throw AuthenticationError.userNotFound
        }
        
        isLoading = true
        defer { isLoading = false }
        
        // In a real implementation, this would delete the user account from the backend
        try await Task.sleep(for: .seconds(1))
        
        try await clearSession()
        
        currentUser = nil
        isAuthenticated = false
        lastError = nil
    }
    
    // MARK: - Session Management
    
    private func saveSession(user: AuthenticatedUser) async throws {
        let sessionData = try JSONEncoder().encode(SessionData(
            userId: user.id,
            email: user.email,
            displayName: user.displayName,
            phoneNumber: user.phoneNumber,
            authenticationMethod: user.authenticationMethod.rawValue,
            isEmailVerified: user.isEmailVerified,
            isPhoneVerified: user.isPhoneVerified,
            lastLoginAt: user.lastLoginAt
        ))
        
        try keychainService.save(data: sessionData, for: sessionKey)
    }
    
    private func restoreSession() async {
        guard let sessionData = try? keychainService.load(for: sessionKey),
              let session = try? JSONDecoder().decode(SessionData.self, from: sessionData),
              let authMethod = AuthenticationMethod(rawValue: session.authenticationMethod) else {
            return
        }
        
        currentUser = AuthenticatedUser(
            id: session.userId,
            email: session.email,
            displayName: session.displayName,
            phoneNumber: session.phoneNumber,
            authenticationMethod: authMethod,
            isEmailVerified: session.isEmailVerified,
            isPhoneVerified: session.isPhoneVerified,
            createdAt: Date(),
            lastLoginAt: session.lastLoginAt
        )
        
        isAuthenticated = true
    }
    
    private func clearSession() async throws {
        try keychainService.delete(for: sessionKey)
    }
    
    // MARK: - Private Implementation
    
    private func performSignIn(with credentials: AuthenticationCredentials) async throws -> AuthenticatedUser {
        // Simulate network request
        try await Task.sleep(for: .seconds(1))
        
        switch credentials.method {
        case .apple:
            return AuthenticatedUser(
                id: credentials.identifier,
                email: credentials.additionalData["email"] as? String,
                displayName: credentials.additionalData["displayName"] as? String,
                authenticationMethod: .apple,
                isEmailVerified: true
            )
            
        case .google:
            let profileImageURLString = credentials.additionalData["profileImageURL"] as? String
            let profileImageURL = profileImageURLString.flatMap { URL(string: $0) }
            
            return AuthenticatedUser(
                id: credentials.identifier,
                email: credentials.additionalData["email"] as? String,
                displayName: credentials.additionalData["displayName"] as? String,
                profileImageURL: profileImageURL,
                authenticationMethod: .google,
                isEmailVerified: true
            )
            
        case .email:
            let isSignUp = credentials.additionalData["isSignUp"] as? Bool ?? false
            
            if isSignUp {
                // Simulate user creation
                return AuthenticatedUser(
                    id: UUID().uuidString,
                    email: credentials.identifier,
                    displayName: credentials.additionalData["displayName"] as? String,
                    authenticationMethod: .email,
                    isEmailVerified: false
                )
            } else {
                // Simulate user lookup
                return AuthenticatedUser(
                    id: UUID().uuidString,
                    email: credentials.identifier,
                    displayName: "Test User",
                    authenticationMethod: .email,
                    isEmailVerified: true
                )
            }
            
        case .phone:
            return AuthenticatedUser(
                id: UUID().uuidString,
                displayName: "Phone User",
                phoneNumber: credentials.identifier,
                authenticationMethod: .phone,
                isPhoneVerified: true
            )
        }
    }
    
    // MARK: - Validation Helpers
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func isValidPassword(_ password: String) -> Bool {
        return password.count >= 8
    }
    
    private func isValidPhoneNumber(_ phoneNumber: String) -> Bool {
        let phoneRegex = #"^\+?[1-9]\d{10,14}$"#
        return phoneNumber.range(of: phoneRegex, options: .regularExpression) != nil
    }
}

// MARK: - Session Data Model

private struct SessionData: Codable {
    let userId: String
    let email: String?
    let displayName: String?
    let phoneNumber: String?
    let authenticationMethod: String
    let isEmailVerified: Bool
    let isPhoneVerified: Bool
    let lastLoginAt: Date
}