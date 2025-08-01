import SwiftUI

@Observable
@MainActor
public final class AppState {
    var isAuthenticated: Bool = true // Temporarily set to true for testing
    var currentUser: User? = User(id: "test", name: "Test User", email: "test@example.com") // Test user
    var hasCompletedOnboarding: Bool = true // Temporarily set to true for testing
    
    public init() {}
    
    func signIn(user: User) {
        self.currentUser = user
        self.isAuthenticated = true
    }
    
    func signOut() {
        self.currentUser = nil
        self.isAuthenticated = false
        self.hasCompletedOnboarding = false
    }
    
    func completeOnboarding() {
        self.hasCompletedOnboarding = true
    }
}

public struct User: Sendable {
    let id: String
    let name: String
    let email: String
    
    public init(id: String, name: String, email: String) {
        self.id = id
        self.name = name
        self.email = email
    }
}