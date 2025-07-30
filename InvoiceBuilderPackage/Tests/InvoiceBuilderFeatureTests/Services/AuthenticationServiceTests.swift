import Testing
import Foundation
@testable import InvoiceBuilderFeature

@Suite("Authentication Service Tests")
struct AuthenticationServiceTests {
    
    @Test("AuthenticationService shared instance exists")
    func sharedInstanceExists() {
        let service = AuthenticationService.shared
        #expect(service != nil)
        #expect(!service.isAuthenticated)
        #expect(service.currentUser == nil)
    }
    
    @Test("Email validation works correctly")
    func emailValidation() async throws {
        let service = AuthenticationService.shared
        
        // Valid emails should not throw
        try await service.signInWithEmail("test@example.com", password: "password123")
        
        // Invalid emails should throw
        await #expect(throws: AuthenticationError.self) {
            try await service.signInWithEmail("invalid-email", password: "password123")
        }
        
        await #expect(throws: AuthenticationError.self) {
            try await service.signInWithEmail("", password: "password123")
        }
    }
    
    @Test("Password validation works correctly")
    func passwordValidation() async throws {
        let service = AuthenticationService.shared
        
        // Valid password should not throw
        try await service.signInWithEmail("test@example.com", password: "password123")
        
        // Weak passwords should throw
        await #expect(throws: AuthenticationError.self) {
            try await service.signInWithEmail("test@example.com", password: "123")
        }
        
        await #expect(throws: AuthenticationError.self) {
            try await service.signInWithEmail("test@example.com", password: "")
        }
    }
    
    @Test("Email sign in creates authenticated user")
    func emailSignInCreatesUser() async throws {
        let service = AuthenticationService.shared
        
        let user = try await service.signInWithEmail("test@example.com", password: "password123")
        
        #expect(user.email == "test@example.com")
        #expect(user.authenticationMethod == .email)
        #expect(service.isAuthenticated)
        #expect(service.currentUser?.email == "test@example.com")
    }
    
    @Test("Email sign up creates new user")
    func emailSignUpCreatesUser() async throws {
        let service = AuthenticationService.shared
        
        let user = try await service.signUpWithEmail(
            "newuser@example.com",
            password: "password123",
            displayName: "Test User"
        )
        
        #expect(user.email == "newuser@example.com")
        #expect(user.displayName == "Test User")
        #expect(user.authenticationMethod == .email)
        #expect(!user.isEmailVerified) // New users start unverified
        #expect(service.isAuthenticated)
    }
    
    @Test("Phone number validation works correctly")
    func phoneNumberValidation() async throws {
        let service = AuthenticationService.shared
        
        // Valid phone numbers should not throw
        try await service.signInWithPhone("+1234567890123", verificationCode: "123456")
        
        // Invalid phone numbers should throw
        await #expect(throws: AuthenticationError.self) {
            try await service.signInWithPhone("invalid", verificationCode: "123456")
        }
        
        await #expect(throws: AuthenticationError.self) {
            try await service.signInWithPhone("", verificationCode: "123456")
        }
    }
    
    @Test("Phone sign in creates authenticated user")
    func phoneSignInCreatesUser() async throws {
        let service = AuthenticationService.shared
        
        let user = try await service.signInWithPhone("+1234567890123", verificationCode: "123456")
        
        #expect(user.phoneNumber == "+1234567890123")
        #expect(user.authenticationMethod == .phone)
        #expect(user.isPhoneVerified)
        #expect(service.isAuthenticated)
    }
    
    @Test("Phone verification can be sent")
    func phoneVerificationSending() async throws {
        let service = AuthenticationService.shared
        
        // Should not throw for valid phone numbers
        try await service.sendPhoneVerification(to: "+1234567890123")
        
        // Should throw for invalid phone numbers
        await #expect(throws: AuthenticationError.self) {
            try await service.sendPhoneVerification(to: "invalid")
        }
    }
    
    @Test("Sign out clears authentication state")
    func signOutClearsState() async throws {
        let service = AuthenticationService.shared
        
        // First sign in
        _ = try await service.signInWithEmail("test@example.com", password: "password123")
        #expect(service.isAuthenticated)
        #expect(service.currentUser != nil)
        
        // Then sign out
        try await service.signOut()
        #expect(!service.isAuthenticated)
        #expect(service.currentUser == nil)
        #expect(service.lastError == nil)
    }
    
    @Test("Delete account clears authentication state")
    func deleteAccountClearsState() async throws {
        let service = AuthenticationService.shared
        
        // First sign in
        _ = try await service.signInWithEmail("test@example.com", password: "password123")
        #expect(service.isAuthenticated)
        #expect(service.currentUser != nil)
        
        // Then delete account
        try await service.deleteAccount()
        #expect(!service.isAuthenticated)
        #expect(service.currentUser == nil)
        #expect(service.lastError == nil)
    }
    
    @Test("Delete account throws when not authenticated")
    func deleteAccountThrowsWhenNotAuthenticated() async throws {
        let service = AuthenticationService.shared
        
        // Ensure not authenticated
        try await service.signOut()
        
        await #expect(throws: AuthenticationError.self) {
            try await service.deleteAccount()
        }
    }
    
    @Test("Authentication credentials are properly created")
    func authenticationCredentialsCreation() {
        let credentials = AuthenticationCredentials(
            method: .email,
            identifier: "test@example.com",
            token: "password123",
            additionalData: ["displayName": "Test User"]
        )
        
        #expect(credentials.method == .email)
        #expect(credentials.identifier == "test@example.com")
        #expect(credentials.token == "password123")
        #expect(credentials.additionalData["displayName"] as? String == "Test User")
    }
    
    @Test("AuthenticatedUser is properly created")
    func authenticatedUserCreation() {
        let user = AuthenticatedUser(
            id: "123",
            email: "test@example.com",
            displayName: "Test User",
            phoneNumber: "+1234567890",
            profileImageURL: URL(string: "https://example.com/image.jpg"),
            authenticationMethod: .email,
            isEmailVerified: true,
            isPhoneVerified: false
        )
        
        #expect(user.id == "123")
        #expect(user.email == "test@example.com")
        #expect(user.displayName == "Test User")
        #expect(user.phoneNumber == "+1234567890")
        #expect(user.profileImageURL?.absoluteString == "https://example.com/image.jpg")
        #expect(user.authenticationMethod == .email)
        #expect(user.isEmailVerified)
        #expect(!user.isPhoneVerified)
    }
    
    @Test("Authentication method display names are correct")
    func authenticationMethodDisplayNames() {
        #expect(AuthenticationMethod.apple.displayName == "Sign in with Apple")
        #expect(AuthenticationMethod.google.displayName == "Sign in with Google")
        #expect(AuthenticationMethod.email.displayName == "Email & Password")
        #expect(AuthenticationMethod.phone.displayName == "Phone Number")
    }
    
    @Test("Authentication errors have proper descriptions")
    func authenticationErrorDescriptions() {
        #expect(AuthenticationError.invalidCredentials.localizedDescription == "Invalid credentials provided")
        #expect(AuthenticationError.userNotFound.localizedDescription == "User account not found")
        #expect(AuthenticationError.networkError.localizedDescription == "Network connection error")
        #expect(AuthenticationError.cancelled.localizedDescription == "Authentication cancelled")
        #expect(AuthenticationError.unknownError.localizedDescription == "An unknown error occurred")
        #expect(AuthenticationError.invalidEmail.localizedDescription == "Invalid email address")
        #expect(AuthenticationError.weakPassword.localizedDescription == "Password is too weak")
        #expect(AuthenticationError.invalidPhoneNumber.localizedDescription == "Invalid phone number")
        #expect(AuthenticationError.verificationFailed.localizedDescription == "Verification failed")
    }
}

@Suite("KeychainService Tests")
struct KeychainServiceTests {
    
    @Test("KeychainService shared instance exists")
    func sharedInstanceExists() {
        let service = KeychainService.shared
        #expect(service != nil)
    }
    
    @Test("Save and load data works correctly")
    func saveAndLoadData() throws {
        let service = KeychainService.shared
        let testKey = "test_key_\(UUID().uuidString)"
        let testData = "Hello, Keychain!".data(using: .utf8)!
        
        // Save data
        try service.save(data: testData, for: testKey)
        
        // Load data
        let loadedData = try service.load(for: testKey)
        let loadedString = String(data: loadedData, encoding: .utf8)
        
        #expect(loadedString == "Hello, Keychain!")
        
        // Clean up
        try service.delete(for: testKey)
    }
    
    @Test("Update existing data works correctly")
    func updateExistingData() throws {
        let service = KeychainService.shared
        let testKey = "test_key_\(UUID().uuidString)"
        let originalData = "Original".data(using: .utf8)!
        let updatedData = "Updated".data(using: .utf8)!
        
        // Save original data
        try service.save(data: originalData, for: testKey)
        
        // Update with new data
        try service.save(data: updatedData, for: testKey)
        
        // Verify updated data
        let loadedData = try service.load(for: testKey)
        let loadedString = String(data: loadedData, encoding: .utf8)
        
        #expect(loadedString == "Updated")
        
        // Clean up
        try service.delete(for: testKey)
    }
    
    @Test("Delete data works correctly")
    func deleteData() throws {
        let service = KeychainService.shared
        let testKey = "test_key_\(UUID().uuidString)"
        let testData = "Test Data".data(using: .utf8)!
        
        // Save data
        try service.save(data: testData, for: testKey)
        
        // Verify it exists
        let _ = try service.load(for: testKey)
        
        // Delete data
        try service.delete(for: testKey)
        
        // Verify it's gone
        #expect(throws: KeychainError.self) {
            try service.load(for: testKey)
        }
    }
    
    @Test("Loading non-existent key throws correct error")
    func loadNonExistentKey() {
        let service = KeychainService.shared
        let nonExistentKey = "non_existent_\(UUID().uuidString)"
        
        #expect(throws: KeychainError.itemNotFound) {
            try service.load(for: nonExistentKey)
        }
    }
    
    @Test("Deleting non-existent key does not throw")
    func deleteNonExistentKey() throws {
        let service = KeychainService.shared
        let nonExistentKey = "non_existent_\(UUID().uuidString)"
        
        // Should not throw
        try service.delete(for: nonExistentKey)
    }
}

@Suite("Apple Sign-In Coordinator Tests")
struct AppleSignInCoordinatorTests {
    
    @Test("AppleSignInCoordinator shared instance exists")
    func sharedInstanceExists() {
        let coordinator = AppleSignInCoordinator.shared
        #expect(coordinator != nil)
        #expect(!coordinator.isPresenting)
        #expect(coordinator.error == nil)
    }
    
    @Test("Credential state check handles various states")
    func credentialStateCheck() async {
        let coordinator = AppleSignInCoordinator.shared
        
        // This would normally require a real Apple ID, so we just test the method exists
        // and doesn't crash with a test user ID
        let state = await coordinator.checkCredentialState(for: "test.user.id")
        
        // The actual state doesn't matter for this test, just that it doesn't crash
        #expect(state != nil)
    }
}

@Suite("Google Sign-In Coordinator Tests")
struct GoogleSignInCoordinatorTests {
    
    @Test("GoogleSignInCoordinator shared instance exists")
    func sharedInstanceExists() {
        let coordinator = GoogleSignInCoordinator.shared
        #expect(coordinator != nil)
        #expect(!coordinator.isPresenting)
        #expect(coordinator.error == nil)
    }
    
    @Test("Configuration method exists and doesn't crash")
    func configurationMethodExists() {
        let coordinator = GoogleSignInCoordinator.shared
        
        // This should not crash even without GoogleService-Info.plist
        coordinator.configure()
        
        // Test passes if no crash occurs
        #expect(true)
    }
    
    @Test("Has previous sign in check works")
    func hasPreviousSignInCheck() {
        let coordinator = GoogleSignInCoordinator.shared
        
        // Should return a boolean without crashing
        let hasPrevious = coordinator.hasPreviousSignIn
        #expect(hasPrevious == true || hasPrevious == false) // Just checking it's a boolean
    }
}