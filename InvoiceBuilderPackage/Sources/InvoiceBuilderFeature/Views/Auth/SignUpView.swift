import SwiftUI

#if os(iOS)
import UIKit
#endif

public struct SignUpView: View {
    @Environment(AuthenticationService.self) private var authService
    @Environment(\.dismiss) private var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var displayName = ""
    @State private var agreedToTerms = false
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "person.crop.circle.badge.plus")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Create Account")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Join Invoice Builder today")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 20)
                    
                    // Social Sign-Up Buttons
                    VStack(spacing: 12) {
                        AppleSignInButton { result in
                            handleAuthResult(result)
                        }
                        
                        GoogleSignInButton { result in
                            handleAuthResult(result)
                        }
                        
                        HStack {
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(.secondary.opacity(0.3))
                            
                            Text("or")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 8)
                            
                            Rectangle()
                                .frame(height: 1)
                                .foregroundStyle(.secondary.opacity(0.3))
                        }
                    }
                    
                    // Sign Up Form
                    VStack(spacing: 16) {
                        TextField("Full Name", text: $displayName)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.name)
                            #if os(iOS)
                            .textInputAutocapitalization(.words)
                            #endif
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.emailAddress)
                            #if os(iOS)
                            .keyboardType(.emailAddress)
                            .textInputAutocapitalization(.never)
                            #endif
                            .autocorrectionDisabled()
                        
                        SecureField("Password", text: $password)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        SecureField("Confirm Password", text: $confirmPassword)
                            .textFieldStyle(.roundedBorder)
                            .textContentType(.newPassword)
                        
                        // Password Requirements
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Image(systemName: password.count >= 8 ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(password.count >= 8 ? .green : .secondary)
                                Text("At least 8 characters")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Spacer()
                            }
                        }
                        .padding(.horizontal, 4)
                        
                        // Terms and Conditions
                        HStack {
                            Button {
                                agreedToTerms.toggle()
                            } label: {
                                Image(systemName: agreedToTerms ? "checkmark.square.fill" : "square")
                                    .foregroundStyle(agreedToTerms ? .blue : .secondary)
                            }
                            
                            Text("I agree to the ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            +
                            Text("Terms of Service")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .underline()
                            +
                            Text(" and ")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            +
                            Text("Privacy Policy")
                                .font(.caption)
                                .foregroundStyle(.blue)
                                .underline()
                            
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                        
                        Button {
                            Task {
                                await signUp()
                            }
                        } label: {
                            Text("Create Account")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(height: 50)
                                .frame(maxWidth: .infinity)
                                .background(.blue)
                                .cornerRadius(8)
                        }
                        .disabled(!isFormValid || authService.isLoading)
                    }
                    
                    // Sign In Link
                    Button {
                        dismiss()
                    } label: {
                        HStack {
                            Text("Already have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("Sign Up")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .overlay {
            if authService.isLoading {
                LoadingOverlay()
            }
        }
        .alert("Sign Up Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !email.isEmpty &&
        !password.isEmpty &&
        !confirmPassword.isEmpty &&
        password == confirmPassword &&
        password.count >= 8 &&
        agreedToTerms
    }
    
    // MARK: - Private Methods
    
    private func handleAuthResult(_ result: Result<AuthenticatedUser, AuthenticationError>) {
        switch result {
        case .success:
            dismiss()
        case .failure(let error):
            if error != .cancelled {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func signUp() async {
        guard password == confirmPassword else {
            alertMessage = "Passwords do not match"
            showingAlert = true
            return
        }
        
        do {
            _ = try await authService.signUpWithEmail(
                email,
                password: password,
                displayName: displayName.isEmpty ? nil : displayName
            )
            dismiss()
        } catch let error as AuthenticationError {
            alertMessage = error.localizedDescription
            showingAlert = true
        } catch {
            alertMessage = "An unexpected error occurred"
            showingAlert = true
        }
    }
}

#Preview {
    SignUpView()
        .environment(AuthenticationService.shared)
}