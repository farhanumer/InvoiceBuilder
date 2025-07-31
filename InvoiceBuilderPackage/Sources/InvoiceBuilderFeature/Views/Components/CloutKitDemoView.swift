import SwiftUI

/// Demo view showing how to integrate iCloud sync functionality
public struct CloudKitDemoView: View {
    @Environment(CloudSyncService.self) private var syncService
    @Environment(NetworkMonitor.self) private var networkMonitor
    @State private var showingSetup = false
    @State private var accountInfo: CloudKitAccountInfo?
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // CloudKit Status Banner
                CloudKitStatusBanner()
                
                // Sync Status
                if syncService.hasProvider {
                    SyncStatusView()
                        .padding()
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                }
                
                // Demo Actions
                VStack(spacing: 12) {
                    if let accountInfo = accountInfo, accountInfo.canSync {
                        Button("Test Sync") {
                            Task {
                                do {
                                    // Test uploading some data
                                    let testData = "Hello CloudKit!".data(using: .utf8)!
                                    syncService.queueSync(
                                        operation: .create,
                                        entityType: "TestEntity",
                                        entityId: UUID(),
                                        data: testData,
                                        priority: .high
                                    )
                                    
                                    try await syncService.syncData()
                                } catch {
                                    print("Sync test failed: \(error)")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        
                        Button("Clear Queue") {
                            syncService.clearSyncQueue()
                        }
                        .buttonStyle(.bordered)
                        
                        if syncService.error != nil {
                            Button("Retry Sync") {
                                Task {
                                    try? await syncService.retrySync()
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                    } else {
                        Button("Setup iCloud Sync") {
                            showingSetup = true
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                
                // Network Status
                HStack {
                    Image(systemName: networkMonitor.isConnected ? "wifi" : "wifi.slash")
                        .foregroundStyle(networkMonitor.isConnected ? .green : .red)
                    
                    Text(networkMonitor.isConnected ? "Online" : "Offline")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Type: \(networkMonitor.connectionType.displayName)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                
                Spacer()
            }
            .padding()
            .navigationTitle("CloudKit Demo")
            .task {
                await updateAccountInfo()
            }
            .sheet(isPresented: $showingSetup) {
                CloudKitSetupView()
            }
        }
    }
    
    private func updateAccountInfo() async {
        accountInfo = await CloudKitSetupService.shared.getAccountStatus()
    }
}

// MARK: - Connection Type Display
// displayName already exists in NetworkMonitor.ConnectionType

// MARK: - Preview

#Preview {
    CloudKitDemoView()
        .withCloudSyncEnvironment()
}