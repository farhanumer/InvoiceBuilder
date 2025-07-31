import Foundation
import SwiftData
import Combine

// MARK: - Cloud Storage Provider Protocol

public protocol CloudStorageProvider: Sendable {
    var isAuthenticated: Bool { get async }
    var providerName: String { get }
    var providerIdentifier: String { get }
    
    func authenticate() async throws
    func signOut() async throws
    
    func uploadData(_ data: Data, to path: String) async throws
    func downloadData(from path: String) async throws -> Data
    func deleteData(at path: String) async throws
    
    func listFiles(in directory: String) async throws -> [CloudFileInfo]
    func fileExists(at path: String) async throws -> Bool
    func getFileInfo(at path: String) async throws -> CloudFileInfo?
}

// MARK: - Cloud File Information

public struct CloudFileInfo: Sendable, Codable {
    public let path: String
    public let name: String
    public let size: Int64
    public let modifiedDate: Date
    public let checksum: String?
    
    public init(path: String, name: String, size: Int64, modifiedDate: Date, checksum: String? = nil) {
        self.path = path
        self.name = name
        self.size = size
        self.modifiedDate = modifiedDate
        self.checksum = checksum
    }
}

// MARK: - Sync Status and Errors

public enum SyncStatus: String, CaseIterable, Sendable {
    case idle = "idle"
    case syncing = "syncing"
    case uploading = "uploading"
    case downloading = "downloading"
    case error = "error"
    case conflict = "conflict"
    
    public var displayName: String {
        switch self {
        case .idle: return "Up to date"
        case .syncing: return "Syncing..."
        case .uploading: return "Uploading..."
        case .downloading: return "Downloading..."
        case .error: return "Sync error"
        case .conflict: return "Conflict detected"
        }
    }
}

public enum CloudSyncError: LocalizedError, Sendable {
    case noProvider
    case providerNotAuthenticated
    case networkUnavailable
    case fileNotFound(String)
    case uploadFailed(String)
    case downloadFailed(String)
    case conflictDetected(String)
    case quotaExceeded
    case unauthorized
    case invalidData
    case syncInProgress
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .noProvider:
            return "No cloud storage provider configured"
        case .providerNotAuthenticated:
            return "Cloud storage provider not authenticated"
        case .networkUnavailable:
            return "Network connection unavailable"
        case .fileNotFound(let path):
            return "File not found: \(path)"
        case .uploadFailed(let reason):
            return "Upload failed: \(reason)"
        case .downloadFailed(let reason):
            return "Download failed: \(reason)"
        case .conflictDetected(let file):
            return "Sync conflict detected for: \(file)"
        case .quotaExceeded:
            return "Cloud storage quota exceeded"
        case .unauthorized:
            return "Unauthorized access to cloud storage"
        case .invalidData:
            return "Invalid data format"
        case .syncInProgress:
            return "Sync operation already in progress"
        case .unknownError(let message):
            return "Unknown error: \(message)"
        }
    }
}

// MARK: - Sync Queue Item

public struct SyncQueueItem: Sendable, Codable {
    public let id: UUID
    public let operation: SyncOperation
    public let entityType: String
    public let entityId: UUID
    public let data: Data
    public let createdAt: Date
    public let priority: SyncPriority
    public var retryCount: Int
    
    public init(
        id: UUID = UUID(),
        operation: SyncOperation,
        entityType: String,
        entityId: UUID,
        data: Data,
        priority: SyncPriority = .normal,
        retryCount: Int = 0
    ) {
        self.id = id
        self.operation = operation
        self.entityType = entityType
        self.entityId = entityId
        self.data = data
        self.createdAt = Date()
        self.priority = priority
        self.retryCount = retryCount
    }
}

public enum SyncOperation: String, CaseIterable, Sendable, Codable {
    case create = "create"
    case update = "update"
    case delete = "delete"
}

public enum SyncPriority: Int, CaseIterable, Sendable, Codable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
}

// MARK: - Cloud Sync Service

@MainActor
@Observable
public final class CloudSyncService: @unchecked Sendable {
    public static let shared = CloudSyncService()
    
    // MARK: - Published Properties
    
    public var currentStatus: SyncStatus = .idle
    public var isOnline: Bool = true
    public var lastSyncDate: Date?
    public var error: CloudSyncError?
    public var progress: Double = 0.0
    public var conflictItems: [SyncConflictItem] = []
    
    // MARK: - Private Properties
    
    private var activeProvider: CloudStorageProvider?
    private var syncQueue: [SyncQueueItem] = []
    private var isSyncing: Bool = false
    private let networkMonitor = NetworkMonitor.shared
    private let maxRetryCount = 3
    private let syncQueueKey = "com.invoicebuilder.syncqueue"
    
    // MARK: - Initialization
    
    private init() {
        setupNetworkMonitoring()
        loadSyncQueue()
    }
    
    // MARK: - Provider Management
    
    public func setProvider(_ provider: CloudStorageProvider) {
        activeProvider = provider
    }
    
    public func removeProvider() {
        activeProvider = nil
    }
    
    public var hasProvider: Bool {
        activeProvider != nil
    }
    
    public var providerName: String? {
        activeProvider?.providerName
    }
    
    // MARK: - Authentication
    
    public func authenticateProvider() async throws {
        guard let provider = activeProvider else {
            throw CloudSyncError.noProvider
        }
        
        try await provider.authenticate()
    }
    
    public func signOutProvider() async throws {
        guard let provider = activeProvider else {
            throw CloudSyncError.noProvider
        }
        
        try await provider.signOut()
        clearError()
    }
    
    public func isProviderAuthenticated() async -> Bool {
        guard let provider = activeProvider else { return false }
        return await provider.isAuthenticated
    }
    
    // MARK: - Sync Operations
    
    public func syncData() async throws {
        guard !isSyncing else {
            throw CloudSyncError.syncInProgress
        }
        
        guard let provider = activeProvider else {
            throw CloudSyncError.noProvider
        }
        
        guard await provider.isAuthenticated else {
            throw CloudSyncError.providerNotAuthenticated
        }
        
        guard networkMonitor.isConnected else {
            // Queue operations for later
            return
        }
        
        do {
            isSyncing = true
            currentStatus = .syncing
            progress = 0.0
            clearError()
            
            // Process sync queue
            try await processSyncQueue()
            
            // Update last sync date
            lastSyncDate = Date()
            currentStatus = .idle
            progress = 1.0
            
        } catch {
            currentStatus = .error
            self.error = error as? CloudSyncError ?? .unknownError(error.localizedDescription)
            isSyncing = false
            throw error
        }
        
        isSyncing = false
    }
    
    public func queueSync(
        operation: SyncOperation,
        entityType: String,
        entityId: UUID,
        data: Data,
        priority: SyncPriority = .normal
    ) {
        let item = SyncQueueItem(
            operation: operation,
            entityType: entityType,
            entityId: entityId,
            data: data,
            priority: priority
        )
        
        // Remove existing items for the same entity
        syncQueue.removeAll { $0.entityId == entityId && $0.entityType == entityType }
        
        // Add new item
        syncQueue.append(item)
        
        // Sort by priority and creation date
        syncQueue.sort { item1, item2 in
            if item1.priority.rawValue != item2.priority.rawValue {
                return item1.priority.rawValue > item2.priority.rawValue
            }
            return item1.createdAt < item2.createdAt
        }
        
        saveSyncQueue()
        
        // Auto-sync if online and not already syncing
        if networkMonitor.isConnected && !isSyncing {
            Task {
                try? await syncData()
            }
        }
    }
    
    public func clearSyncQueue() {
        syncQueue.removeAll()
        saveSyncQueue()
    }
    
    public var queuedItemsCount: Int {
        syncQueue.count
    }
    
    // MARK: - Conflict Resolution
    
    public func resolveConflict(_ conflict: SyncConflictItem, resolution: ConflictResolution) async throws {
        switch resolution {
        case .useLocal:
            try await uploadConflictItem(conflict, useLocal: true)
        case .useRemote:
            try await downloadConflictItem(conflict, useRemote: true)
        case .merge:
            // For now, default to local - merge logic would be entity-specific
            try await uploadConflictItem(conflict, useLocal: true)
        }
        
        // Remove from conflicts
        conflictItems.removeAll { $0.id == conflict.id }
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
    
    public func retrySync() async throws {
        clearError()
        try await syncData()
    }
    
    // MARK: - Private Methods
    
    private func setupNetworkMonitoring() {
        networkMonitor.onNetworkChange = { [weak self] isConnected in
            Task { @MainActor in
                self?.isOnline = isConnected
                
                // Auto-sync when network becomes available
                if isConnected && !(self?.isSyncing ?? true) && !(self?.syncQueue.isEmpty ?? true) {
                    try? await self?.syncData()
                }
            }
        }
        networkMonitor.startMonitoring()
    }
    
    private func processSyncQueue() async throws {
        let totalItems = syncQueue.count
        var processedItems = 0
        
        for (index, item) in syncQueue.enumerated() {
            do {
                try await processSyncItem(item)
                syncQueue.remove(at: index - processedItems)
                processedItems += 1
            } catch {
                // Handle retry logic
                if item.retryCount < maxRetryCount {
                    var retryItem = item
                    retryItem.retryCount += 1
                    syncQueue[index - processedItems] = retryItem
                } else {
                    // Max retries reached, remove from queue
                    syncQueue.remove(at: index - processedItems)
                    processedItems += 1
                    
                    // Log error or notify user
                    print("Sync item failed after \(maxRetryCount) retries: \(error)")
                }
            }
            
            // Update progress
            progress = Double(processedItems) / Double(totalItems)
        }
        
        saveSyncQueue()
    }
    
    private func processSyncItem(_ item: SyncQueueItem) async throws {
        guard let provider = activeProvider else {
            throw CloudSyncError.noProvider
        }
        
        let filePath = "\(item.entityType)/\(item.entityId.uuidString).json"
        
        switch item.operation {
        case .create, .update:
            currentStatus = .uploading
            try await provider.uploadData(item.data, to: filePath)
            
        case .delete:
            try await provider.deleteData(at: filePath)
        }
    }
    
    private func uploadConflictItem(_ conflict: SyncConflictItem, useLocal: Bool) async throws {
        guard let provider = activeProvider else {
            throw CloudSyncError.noProvider
        }
        
        if useLocal {
            try await provider.uploadData(conflict.localData, to: conflict.filePath)
        }
    }
    
    private func downloadConflictItem(_ conflict: SyncConflictItem, useRemote: Bool) async throws {
        guard let provider = activeProvider else {
            throw CloudSyncError.noProvider
        }
        
        if useRemote {
            let _ = try await provider.downloadData(from: conflict.filePath)
            // Update local data would happen here
            // This would need to integrate with SwiftData
        }
    }
    
    private func saveSyncQueue() {
        do {
            let data = try JSONEncoder().encode(syncQueue)
            UserDefaults.standard.set(data, forKey: syncQueueKey)
        } catch {
            print("Failed to save sync queue: \(error)")
        }
    }
    
    private func loadSyncQueue() {
        guard let data = UserDefaults.standard.data(forKey: syncQueueKey) else { return }
        
        do {
            syncQueue = try JSONDecoder().decode([SyncQueueItem].self, from: data)
        } catch {
            print("Failed to load sync queue: \(error)")
            syncQueue = []
        }
    }
}

// MARK: - Sync Conflict

public struct SyncConflictItem: Sendable, Identifiable {
    public let id: UUID
    public let filePath: String
    public let entityType: String
    public let entityId: UUID
    public let localData: Data
    public let remoteData: Data
    public let localModifiedDate: Date
    public let remoteModifiedDate: Date
    
    public init(
        id: UUID = UUID(),
        filePath: String,
        entityType: String,
        entityId: UUID,
        localData: Data,
        remoteData: Data,
        localModifiedDate: Date,
        remoteModifiedDate: Date
    ) {
        self.id = id
        self.filePath = filePath
        self.entityType = entityType
        self.entityId = entityId
        self.localData = localData
        self.remoteData = remoteData
        self.localModifiedDate = localModifiedDate
        self.remoteModifiedDate = remoteModifiedDate
    }
}

public enum ConflictResolution: CaseIterable, Sendable {
    case useLocal
    case useRemote
    case merge
    
    public var displayName: String {
        switch self {
        case .useLocal: return "Use Local"
        case .useRemote: return "Use Remote"
        case .merge: return "Merge"
        }
    }
}


