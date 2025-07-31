import Foundation
import CloudKit

/// Service responsible for configuring CloudKit and setting up iCloud provider
@MainActor
public final class CloudKitSetupService {
    public static let shared = CloudKitSetupService()
    
    private var syncService: CloudSyncService {
        CloudSyncService.shared
    }
    
    private var cloudProvider: iCloudProvider {
        iCloudProvider.shared
    }
    
    private init() {}
    
    /// Initialize CloudKit and set up the sync service
    public func initializeCloudKit() async throws {
        // Set the iCloud provider as the active provider
        syncService.setProvider(cloudProvider)
        
        // Check if user is authenticated
        let isAuthenticated = await cloudProvider.isAuthenticated
        
        if isAuthenticated {
            // Set up push notification subscriptions for real-time sync
            try await setupPushNotifications()
        }
    }
    
    /// Authenticate the user with iCloud
    public func authenticateIfNeeded() async throws {
        let isAuthenticated = await cloudProvider.isAuthenticated
        
        if !isAuthenticated {
            try await cloudProvider.authenticate()
            
            // After authentication, set up push notifications
            try await setupPushNotifications()
        }
    }
    
    /// Set up CloudKit push notifications for real-time sync
    private func setupPushNotifications() async throws {
        do {
            try await cloudProvider.subscribeToChanges()
        } catch {
            // Log error but don't fail initialization
            print("Failed to set up push notifications: \(error)")
        }
    }
    
    /// Check CloudKit account status and provide user-friendly information
    public func getAccountStatus() async -> CloudKitAccountInfo {
        let accountStatus = cloudProvider.accountStatus
        let isAuthenticated = await cloudProvider.isAuthenticated
        
        return CloudKitAccountInfo(
            status: accountStatus,
            isAuthenticated: isAuthenticated,
            hasProvider: syncService.hasProvider,
            error: cloudProvider.error
        )
    }
    
    /// Sign out from iCloud
    public func signOut() async throws {
        try await cloudProvider.signOut()
        
        // Optionally remove the provider
        // syncService.removeProvider()
    }
}

// MARK: - Account Information

public struct CloudKitAccountInfo {
    public let status: CKAccountStatus
    public let isAuthenticated: Bool
    public let hasProvider: Bool
    public let error: iCloudError?
    
    public var displayMessage: String {
        if let error = error {
            return error.localizedDescription
        }
        
        switch status {
        case .available:
            return isAuthenticated ? "Connected to iCloud" : "iCloud available but not authenticated"
        case .noAccount:
            return "No iCloud account found. Please sign in to iCloud in Settings."
        case .restricted:
            return "iCloud access is restricted on this device."
        case .couldNotDetermine:
            return "Unable to determine iCloud status."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable."
        @unknown default:
            return "Unknown iCloud status."
        }
    }
    
    public var canSync: Bool {
        return status == .available && isAuthenticated && hasProvider
    }
}