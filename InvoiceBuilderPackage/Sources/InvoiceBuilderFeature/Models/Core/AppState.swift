import SwiftUI

@Observable
@MainActor
public final class AppState {
    var isAuthenticated: Bool = false
    var currentUser: User?
    var hasCompletedOnboarding: Bool = false
    
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