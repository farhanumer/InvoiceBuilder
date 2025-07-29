import SwiftUI

@Observable
@MainActor
public final class AuthenticationService {
    public var isAuthenticated: Bool = false
    public var currentUser: User?
    
    public init() {}
    
    public func signInWithApple() async throws {
        // TODO: Implement Apple Sign-In
        await MainActor.run {
            let user = User(id: "apple_\(UUID().uuidString)", name: "Apple User", email: "apple@example.com")
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    public func signInWithGoogle() async throws {
        // TODO: Implement Google Sign-In
        await MainActor.run {
            let user = User(id: "google_\(UUID().uuidString)", name: "Google User", email: "google@example.com")
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    public func signInWithEmail(_ email: String, password: String) async throws {
        // TODO: Implement email/password authentication
        await MainActor.run {
            let user = User(id: "email_\(UUID().uuidString)", name: "Email User", email: email)
            self.currentUser = user
            self.isAuthenticated = true
        }
    }
    
    public func signOut() {
        currentUser = nil
        isAuthenticated = false
    }
}