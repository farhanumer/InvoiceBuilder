import Foundation
import AuthenticationServices
import SwiftUI

@MainActor
public final class AppleSignInCoordinator: NSObject, ObservableObject {
    public static let shared = AppleSignInCoordinator()
    
    @Published public var isPresenting = false
    @Published public var error: AuthenticationError?
    
    private var continuation: CheckedContinuation<ASAuthorization, Error>?
    
    private override init() {
        super.init()
    }
    
    public func signIn() async throws -> ASAuthorization {
        return try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            let request = appleIDProvider.createRequest()
            request.requestedScopes = [.fullName, .email]
            
            let authorizationController = ASAuthorizationController(authorizationRequests: [request])
            authorizationController.delegate = self
            authorizationController.presentationContextProvider = self
            authorizationController.performRequests()
        }
    }
    
    public func checkCredentialState(for userID: String) async -> ASAuthorizationAppleIDProvider.CredentialState {
        return await withCheckedContinuation { continuation in
            let appleIDProvider = ASAuthorizationAppleIDProvider()
            appleIDProvider.getCredentialState(forUserID: userID) { state, error in
                continuation.resume(returning: state)
            }
        }
    }
}

// MARK: - ASAuthorizationControllerDelegate

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        continuation?.resume(returning: authorization)
        continuation = nil
        isPresenting = false
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        let authError: AuthenticationError
        
        if let authorizationError = error as? ASAuthorizationError {
            switch authorizationError.code {
            case .canceled:
                authError = .cancelled
            case .failed:
                authError = .invalidCredentials
            case .invalidResponse:
                authError = .networkError
            case .notHandled:
                authError = .unknownError
            case .unknown:
                authError = .unknownError
            case .notInteractive:
                authError = .unknownError
            @unknown default:
                authError = .unknownError
            }
        } else {
            authError = .unknownError
        }
        
        self.error = authError
        continuation?.resume(throwing: authError)
        continuation = nil
        isPresenting = false
    }
}

// MARK: - ASAuthorizationControllerPresentationContextProviding

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        #if os(iOS)
        return UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first { $0.isKeyWindow } ?? UIWindow()
        #elseif os(macOS)
        return NSApplication.shared.windows.first ?? NSWindow()
        #endif
    }
}

// MARK: - SwiftUI Sign In Button

public struct AppleSignInButton: View {
    let onCompletion: (Result<AuthenticatedUser, AuthenticationError>) -> Void
    
    @StateObject private var coordinator = AppleSignInCoordinator.shared
    @Environment(\.colorScheme) private var colorScheme
    
    public init(onCompletion: @escaping (Result<AuthenticatedUser, AuthenticationError>) -> Void) {
        self.onCompletion = onCompletion
    }
    
    public var body: some View {
        Button {
            Task {
                do {
                    coordinator.isPresenting = true
                    let authorization = try await coordinator.signIn()
                    let user = try await AuthenticationService.shared.signInWithApple(authorization: authorization)
                    onCompletion(.success(user))
                } catch let error as AuthenticationError {
                    onCompletion(.failure(error))
                } catch {
                    onCompletion(.failure(.unknownError))
                }
            }
        } label: {
            HStack {
                Image(systemName: "applelogo")
                    .font(.system(size: 16, weight: .medium))
                Text("Sign in with Apple")
                    .font(.system(size: 16, weight: .medium))
            }
            .foregroundColor(colorScheme == .dark ? .black : .white)
            .frame(height: 50)
            .frame(maxWidth: .infinity)
            .background(colorScheme == .dark ? .white : .black)
            .cornerRadius(8)
        }
        .disabled(coordinator.isPresenting)
    }
}

// MARK: - UIKit Sign In Button (for integration with UIKit views if needed)

#if os(iOS)
import UIKit

public final class AppleSignInUIButton: UIView {
    private let button: ASAuthorizationAppleIDButton
    private let onCompletion: (Result<AuthenticatedUser, AuthenticationError>) -> Void
    
    public init(
        type: ASAuthorizationAppleIDButton.ButtonType = .signIn,
        style: ASAuthorizationAppleIDButton.Style = .black,
        onCompletion: @escaping (Result<AuthenticatedUser, AuthenticationError>) -> Void
    ) {
        self.button = ASAuthorizationAppleIDButton(authorizationButtonType: type, authorizationButtonStyle: style)
        self.onCompletion = onCompletion
        
        super.init(frame: .zero)
        
        setupButton()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupButton() {
        addSubview(button)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            button.topAnchor.constraint(equalTo: topAnchor),
            button.leadingAnchor.constraint(equalTo: leadingAnchor),
            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.bottomAnchor.constraint(equalTo: bottomAnchor),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        button.addTarget(self, action: #selector(appleSignInTapped), for: .touchUpInside)
    }
    
    @objc private func appleSignInTapped() {
        Task { @MainActor in
            do {
                let authorization = try await AppleSignInCoordinator.shared.signIn()
                let user = try await AuthenticationService.shared.signInWithApple(authorization: authorization)
                onCompletion(.success(user))
            } catch let error as AuthenticationError {
                onCompletion(.failure(error))
            } catch {
                onCompletion(.failure(.unknownError))
            }
        }
    }
}
#endif