import Foundation
import GoogleSignIn
import SwiftUI

#if os(iOS)
import UIKit
#endif

@MainActor
public final class GoogleSignInCoordinator: ObservableObject {
    public static let shared = GoogleSignInCoordinator()
    
    @Published public var isPresenting = false
    @Published public var error: AuthenticationError?
    
    private init() {}
    
    public func configure() {
        // This should be called in the app startup
        // The client ID should be configured from GoogleService-Info.plist
        guard let path = Bundle.main.path(forResource: "GoogleService-Info", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path),
              let clientId = plist["CLIENT_ID"] as? String else {
            print("Warning: GoogleService-Info.plist not found or CLIENT_ID missing")
            return
        }
        
        let config = GIDConfiguration(clientID: clientId)
        
        GIDSignIn.sharedInstance.configuration = config
    }
    
    public func signIn() async throws -> GIDSignInResult {
        return try await withCheckedThrowingContinuation { continuation in
            #if os(iOS)
            guard let presentingViewController = self.presentingViewController else {
                continuation.resume(throwing: AuthenticationError.unknownError)
                return
            }
            
            isPresenting = true
            
            GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
                DispatchQueue.main.async {
                    self?.isPresenting = false
                    
                    if let error = error {
                        let authError = self?.mapGoogleError(error) ?? .unknownError
                        self?.error = authError
                        continuation.resume(throwing: authError)
                    } else if let result = result {
                        continuation.resume(returning: result)
                    } else {
                        let authError = AuthenticationError.unknownError
                        self?.error = authError
                        continuation.resume(throwing: authError)
                    }
                }
            }
            #else
            // macOS not supported in this implementation
            continuation.resume(throwing: AuthenticationError.unknownError)
            #endif
        }
    }
    
    public func signOut() throws {
        GIDSignIn.sharedInstance.signOut()
    }
    
    public func restorePreviousSignIn() async throws -> GIDSignInResult? {
        return try await withCheckedThrowingContinuation { continuation in
            GIDSignIn.sharedInstance.restorePreviousSignIn { [weak self] user, error in
                DispatchQueue.main.async {
                    if let error = error {
                        let authError = self?.mapGoogleError(error) ?? .unknownError
                        self?.error = authError
                        continuation.resume(throwing: authError)
                    } else if let user = user {
                        // For now, return nil since we can't easily mock GIDSignInResult
                        // In a real implementation, you'd handle the restored user properly
                        continuation.resume(returning: nil)
                    } else {
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    }
    
    public var hasPreviousSignIn: Bool {
        return GIDSignIn.sharedInstance.hasPreviousSignIn()
    }
    
    // MARK: - Private Helpers
    
    #if os(iOS)
    private var presentingViewController: UIViewController? {
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow }?
            .rootViewController
    }
    #endif
    
    private func mapGoogleError(_ error: Error) -> AuthenticationError {
        guard let gidError = error as? GIDSignInError else {
            return .unknownError
        }
        
        switch gidError.code {
        case .canceled:
            return .cancelled
        case .EMM:
            return .networkError
        case .hasNoAuthInKeychain:
            return .userNotFound
        case .mismatchWithCurrentUser:
            return .invalidCredentials
        case .scopesAlreadyGranted:
            return .unknownError
        case .unknown:
            return .unknownError
        @unknown default:
            return .unknownError
        }
    }
}

// MARK: - SwiftUI Google Sign In Button

public struct GoogleSignInButton: View {
    let onCompletion: (Result<AuthenticatedUser, AuthenticationError>) -> Void
    
    @StateObject private var coordinator = GoogleSignInCoordinator.shared
    @Environment(\.colorScheme) private var colorScheme
    
    public init(onCompletion: @escaping (Result<AuthenticatedUser, AuthenticationError>) -> Void) {
        self.onCompletion = onCompletion
    }
    
    public var body: some View {
        Button {
            // For now, show an alert that Google Sign-In is not available
            onCompletion(.failure(.unknownError))
        } label: {
            HStack {
                Image(systemName: "globe")
                    .font(.system(size: 16, weight: .medium))
                Text("Sign in with Google (Coming Soon)")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(.gray)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(.gray, lineWidth: 1)
            )
        }
        .disabled(true)
    }
}

// MARK: - Configuration Helper

public extension GoogleSignInCoordinator {
    static func configureFromInfoPlist() {
        shared.configure()
    }
}