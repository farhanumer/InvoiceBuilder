import SwiftUI

#if os(iOS)
import UIKit
#endif

public struct LoginView: View {
    @Environment(AuthenticationService.self) private var authService
    @State private var email = ""
    @State private var password = ""
    @State private var phoneNumber = ""
    @State private var verificationCode = ""
    @State private var showingSignUp = false
    @State private var showingPhoneVerification = false
    @State private var selectedAuthMethod: AuthenticationMethod = .email
    @State private var alertMessage = ""
    @State private var showingAlert = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.blue)
                        
                        Text("Invoice Builder")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Sign in to your account")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 40)
                    
                    // Social Sign-In Buttons
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
                    
                    // Auth Method Selection
                    Picker("Authentication Method", selection: $selectedAuthMethod) {
                        Text(AuthenticationMethod.email.displayName)
                            .tag(AuthenticationMethod.email)
                        Text(AuthenticationMethod.phone.displayName)
                            .tag(AuthenticationMethod.phone)
                    }
                    .pickerStyle(.segmented)
                    
                    // Email/Phone Authentication Form
                    VStack(spacing: 16) {
                        if selectedAuthMethod == .email {
                            emailAuthForm
                        } else {
                            phoneAuthForm
                        }
                    }
                    
                    // Sign Up Link
                    Button {
                        showingSignUp = true
                    } label: {
                        HStack {
                            Text("Don't have an account?")
                                .foregroundStyle(.secondary)
                            Text("Sign Up")
                                .fontWeight(.semibold)
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 24)
            }
            .navigationTitle("")
            .navigationBarHidden(true)
        }
        .overlay {
            if authService.isLoading {
                LoadingOverlay()
            }
        }
        .sheet(isPresented: $showingSignUp) {
            SignUpView()
        }
        .sheet(isPresented: $showingPhoneVerification) {
            PhoneVerificationView(phoneNumber: phoneNumber) { code in
                verificationCode = code
                Task {
                    await signInWithPhone()
                }
            }
        }
        .alert("Authentication Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .onAppear {
            GoogleSignInCoordinator.configureFromInfoPlist()
        }
    }
    
    @ViewBuilder
    private var emailAuthForm: some View {
        VStack(spacing: 16) {
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
                .textContentType(.password)
            
            Button {
                Task {
                    await signInWithEmail()
                }
            } label: {
                Text("Sign In")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .cornerRadius(8)
            }
            .disabled(email.isEmpty || password.isEmpty || authService.isLoading)
        }
    }
    
    @ViewBuilder
    private var phoneAuthForm: some View {
        VStack(spacing: 16) {
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(.roundedBorder)
                .textContentType(.telephoneNumber)
                #if os(iOS)
                .keyboardType(.phonePad)
                #endif
            
            Button {
                Task {
                    await sendPhoneVerification()
                }
            } label: {
                Text("Send Verification Code")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(height: 50)
                    .frame(maxWidth: .infinity)
                    .background(.blue)
                    .cornerRadius(8)
            }
            .disabled(phoneNumber.isEmpty || authService.isLoading)
        }
    }
    
    // MARK: - Private Methods
    
    private func handleAuthResult(_ result: Result<AuthenticatedUser, AuthenticationError>) {
        switch result {
        case .success:
            // Authentication successful - handled by the service
            break
        case .failure(let error):
            if error != .cancelled {
                alertMessage = error.localizedDescription
                showingAlert = true
            }
        }
    }
    
    private func signInWithEmail() async {
        do {
            _ = try await authService.signInWithEmail(email, password: password)
        } catch let error as AuthenticationError {
            alertMessage = error.localizedDescription
            showingAlert = true
        } catch {
            alertMessage = "An unexpected error occurred"
            showingAlert = true
        }
    }
    
    private func sendPhoneVerification() async {
        do {
            try await authService.sendPhoneVerification(to: phoneNumber)
            showingPhoneVerification = true
        } catch let error as AuthenticationError {
            alertMessage = error.localizedDescription
            showingAlert = true
        } catch {
            alertMessage = "Failed to send verification code"
            showingAlert = true
        }
    }
    
    private func signInWithPhone() async {
        do {
            _ = try await authService.signInWithPhone(phoneNumber, verificationCode: verificationCode)
            showingPhoneVerification = false
        } catch let error as AuthenticationError {
            alertMessage = error.localizedDescription
            showingAlert = true
        } catch {
            alertMessage = "Verification failed"
            showingAlert = true
        }
    }
}

// MARK: - Supporting Views

struct LoadingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 16) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Signing in...")
                    .font(.headline)
            }
            .padding(24)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        }
    }
}

struct PhoneVerificationView: View {
    let phoneNumber: String
    let onCodeEntered: (String) -> Void
    
    @State private var code = ""
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "message.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Enter Verification Code")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    Text("We sent a code to \(phoneNumber)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                TextField("Verification Code", text: $code)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                    .textContentType(.oneTimeCode)
                
                Button {
                    onCodeEntered(code)
                } label: {
                    Text("Verify")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .background(.blue)
                        .cornerRadius(8)
                }
                .disabled(code.isEmpty)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            .navigationTitle("Verification")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LoginView()
        .environment(AuthenticationService.shared)
}