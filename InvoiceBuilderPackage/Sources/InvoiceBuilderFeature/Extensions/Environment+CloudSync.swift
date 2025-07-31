import SwiftUI

// MARK: - Environment Setup Extensions

extension View {
    /// Configure the CloudSync environment for the view hierarchy
    public func withCloudSyncEnvironment() -> some View {
        self
            .environment(CloudSyncService.shared)
            .environment(NetworkMonitor.shared)
            .task {
                // Initialize CloudKit when the view appears
                do {
                    try await CloudKitSetupService.shared.initializeCloudKit()
                } catch {
                    print("Failed to initialize CloudKit: \(error)")
                }
            }
    }
    
    /// Authenticate with iCloud if needed when the view appears
    public func withiCloudAuthentication() -> some View {
        self.task {
            do {
                try await CloudKitSetupService.shared.authenticateIfNeeded()
            } catch {
                print("iCloud authentication failed: \(error)")
            }
        }
    }
}

// MARK: - CloudSync Environment Values
// Using the simpler approach with direct .environment() calls in the view hierarchy

// MARK: - CloudKit Status View

public struct CloudKitStatusBanner: View {
    @State private var accountInfo: CloudKitAccountInfo?
    @State private var showingDetails = false
    
    public init() {}
    
    public var body: some View {
        if let accountInfo = accountInfo, !accountInfo.canSync {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundStyle(statusColor)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("iCloud Sync")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text(accountInfo.displayMessage)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("Setup") {
                    showingDetails = true
                }
                .font(.caption)
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
            .task {
                await updateAccountInfo()
            }
            .sheet(isPresented: $showingDetails) {
                CloudKitSetupView()
            }
        }
    }
    
    private var statusIcon: String {
        guard let accountInfo = accountInfo else { return "icloud" }
        
        switch accountInfo.status {
        case .available:
            return accountInfo.isAuthenticated ? "icloud" : "icloud.slash"
        case .noAccount:
            return "icloud.slash"
        case .restricted:
            return "icloud.slash"
        default:
            return "icloud.slash"
        }
    }
    
    private var statusColor: Color {
        guard let accountInfo = accountInfo else { return .gray }
        
        switch accountInfo.status {
        case .available:
            return accountInfo.isAuthenticated ? .green : .orange
        default:
            return .red
        }
    }
    
    private func updateAccountInfo() async {
        accountInfo = await CloudKitSetupService.shared.getAccountStatus()
    }
}

// MARK: - CloudKit Setup View

public struct CloudKitSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var accountInfo: CloudKitAccountInfo?
    @State private var isAuthenticating = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                if let accountInfo = accountInfo {
                    statusSection(accountInfo)
                    
                    if !accountInfo.canSync {
                        actionSection(accountInfo)
                    }
                } else {
                    ProgressView("Checking iCloud status...")
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("iCloud Sync Setup")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .task {
                await updateAccountInfo()
            }
        }
    }
    
    @ViewBuilder
    private func statusSection(_ accountInfo: CloudKitAccountInfo) -> some View {
        VStack(spacing: 12) {
            Image(systemName: accountInfo.canSync ? "icloud" : "icloud.slash")
                .font(.largeTitle)
                .foregroundStyle(accountInfo.canSync ? .green : .orange)
            
            Text(accountInfo.displayMessage)
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
        }
    }
    
    @ViewBuilder
    private func actionSection(_ accountInfo: CloudKitAccountInfo) -> some View {
        VStack(spacing: 16) {
            switch accountInfo.status {
            case .available:
                if !accountInfo.isAuthenticated {
                    Button("Connect to iCloud") {
                        Task {
                            await authenticate()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isAuthenticating)
                }
                
            case .noAccount:
                Text("Please sign in to iCloud in the Settings app, then return to this app.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.yellow.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                
            case .restricted:
                Text("iCloud access is restricted on this device. Check your device restrictions in Settings.")
                    .multilineTextAlignment(.center)
                    .padding()
                    .background(.red.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
                
            default:
                Button("Retry") {
                    Task {
                        await updateAccountInfo()
                    }
                }
                .buttonStyle(.bordered)
            }
            
            if isAuthenticating {
                ProgressView("Connecting...")
                    .scaleEffect(0.8)
            }
        }
    }
    
    private func authenticate() async {
        isAuthenticating = true
        
        do {
            try await CloudKitSetupService.shared.authenticateIfNeeded()
            await updateAccountInfo()
        } catch {
            print("Authentication failed: \(error)")
        }
        
        isAuthenticating = false
    }
    
    private func updateAccountInfo() async {
        accountInfo = await CloudKitSetupService.shared.getAccountStatus()
    }
}