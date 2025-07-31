import Foundation
import SwiftData

// MARK: - Syncable Entity Protocol

public protocol SyncableEntity: PersistentModel {
    var id: UUID { get }
    var lastModified: Date { get set }
    var syncStatus: SyncEntityStatus { get set }
    
    /// The entity type name for sync operations
    static var syncEntityType: String { get }
    
    /// Convert to data for sync
    func toSyncData() throws -> Data
    
    /// Update from sync data
    func updateFromSyncData(_ data: Data) throws
}

// MARK: - Sync Entity Status

public enum SyncEntityStatus: String, CaseIterable, Sendable, Codable {
    case synced = "synced"
    case pending = "pending"
    case uploading = "uploading"
    case downloading = "downloading"
    case conflicted = "conflicted"
    case error = "error"
    
    public var displayName: String {
        switch self {
        case .synced: return "Synced"
        case .pending: return "Pending"
        case .uploading: return "Uploading"
        case .downloading: return "Downloading"
        case .conflicted: return "Conflicted"
        case .error: return "Error"
        }
    }
    
    public var needsSync: Bool {
        switch self {
        case .pending, .error:
            return true
        case .synced, .uploading, .downloading, .conflicted:
            return false
        }
    }
}

// MARK: - Sync Extensions

extension CloudSyncService {
    
    /// Queue sync operation for a syncable entity
    public func queueEntitySync<T: SyncableEntity>(
        _ entity: T,
        operation: SyncOperation,
        priority: SyncPriority = .normal
    ) {
        do {
            let data = try entity.toSyncData()
            
            queueSync(
                operation: operation,
                entityType: T.syncEntityType,
                entityId: entity.id,
                data: data,
                priority: priority
            )
            
            // Update entity sync status
            entity.syncStatus = .pending
            entity.lastModified = Date()
            
        } catch {
            entity.syncStatus = .error
            print("Failed to queue sync for entity \(entity.id): \(error)")
        }
    }
    
    /// Sync all pending entities of a specific type
    public func syncPendingEntities<T: SyncableEntity>(
        ofType entityType: T.Type,
        from context: ModelContext
    ) async throws {
        let predicate = #Predicate<T> { entity in
            entity.syncStatus.rawValue == "pending" || entity.syncStatus.rawValue == "error"
        }
        
        let descriptor = FetchDescriptor(predicate: predicate)
        let pendingEntities = try context.fetch(descriptor)
        
        for entity in pendingEntities {
            queueEntitySync(entity, operation: .update, priority: .normal)
        }
        
        if !pendingEntities.isEmpty {
            try await syncData()
        }
    }
    
    /// Mark entity as synced
    public func markEntityAsSynced<T: SyncableEntity>(_ entity: T) {
        entity.syncStatus = .synced
    }
    
    /// Mark entity as conflicted
    public func markEntityAsConflicted<T: SyncableEntity>(_ entity: T) {
        entity.syncStatus = .conflicted
    }
}

// MARK: - Auto Sync Helper

/// Helper methods for automatic sync triggering
public enum AutoSyncHelper {
    
    /// Trigger sync for an entity when modified
    @MainActor
    public static func triggerSync<T: SyncableEntity>(
        for entity: T,
        operation: SyncOperation = .update,
        priority: SyncPriority = .normal
    ) {
        let syncService = CloudSyncService.shared
        syncService.queueEntitySync(entity, operation: operation, priority: priority)
    }
}

// MARK: - Model Context Extensions

extension ModelContext {
    
    /// Save and sync all modified entities
    public func saveAndSync() throws {
        // First save to local database
        try save()
        
        // Then queue sync for all pending entities
        Task { @MainActor in
            let syncService = CloudSyncService.shared
            try? await syncService.syncData()
        }
        
        // This would need to be expanded to handle all entity types
        // For now, we'll implement this when we add sync support to specific entities
    }
    
    /// Get all entities that need sync
    public func getPendingSyncEntities<T: SyncableEntity>(ofType entityType: T.Type) throws -> [T] {
        let predicate = #Predicate<T> { entity in
            entity.syncStatus.rawValue == "pending" || entity.syncStatus.rawValue == "error"
        }
        
        let descriptor = FetchDescriptor(predicate: predicate)
        return try fetch(descriptor)
    }
}

// MARK: - Sync Data Models

/// Generic sync data wrapper for entities
public struct SyncEntityData: Codable, Sendable {
    public let entityType: String
    public let entityId: UUID
    public let data: Data
    public let lastModified: Date
    public let version: Int
    
    public init(entityType: String, entityId: UUID, data: Data, lastModified: Date, version: Int = 1) {
        self.entityType = entityType
        self.entityId = entityId
        self.data = data
        self.lastModified = lastModified
        self.version = version
    }
}

/// Batch sync operation for multiple entities
public struct SyncBatch: Codable, Sendable {
    public let id: UUID
    public let entities: [SyncEntityData]
    public let createdAt: Date
    
    public init(entities: [SyncEntityData]) {
        self.id = UUID()
        self.entities = entities
        self.createdAt = Date()
    }
}

// MARK: - Sync Utilities

public enum SyncUtils {
    
    /// Generate checksum for data integrity
    public static func generateChecksum(for data: Data) -> String {
        return data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
    
    /// Compare two dates for sync conflict detection
    public static func hasConflict(localDate: Date, remoteDate: Date, tolerance: TimeInterval = 1.0) -> Bool {
        return abs(localDate.timeIntervalSince(remoteDate)) > tolerance
    }
    
    /// Generate sync file path for entity
    public static func syncFilePath(for entityType: String, entityId: UUID) -> String {
        return "\(entityType)/\(entityId.uuidString).json"
    }
    
    /// Generate batch sync file path
    public static func batchSyncFilePath(for batchId: UUID) -> String {
        return "batches/\(batchId.uuidString).json"
    }
}