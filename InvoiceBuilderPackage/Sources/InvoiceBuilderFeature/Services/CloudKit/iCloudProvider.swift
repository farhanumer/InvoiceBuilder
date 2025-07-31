import Foundation
import CloudKit
import Combine

@MainActor
@Observable
public final class iCloudProvider: CloudStorageProvider, @unchecked Sendable {
    public static let shared = iCloudProvider()
    
    // MARK: - CloudStorageProvider Properties
    
    nonisolated public var providerName: String { "iCloud" }
    nonisolated public var providerIdentifier: String { "com.apple.icloud" }
    
    // MARK: - Public Properties
    
    public var accountStatus: CKAccountStatus = .couldNotDetermine
    public var error: iCloudError?
    
    // MARK: - Private Properties
    
    private let container: CKContainer
    private let privateDatabase: CKDatabase
    private let publicDatabase: CKDatabase
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Record Types
    
    private enum RecordType {
        static let invoice = "Invoice"
        static let client = "Client"
        static let businessProfile = "BusinessProfile"
        static let serviceItem = "ServiceItem"
        static let invoiceItem = "InvoiceItem"
        static let syncData = "SyncData"
    }
    
    // MARK: - Initialization
    
    private init() {
        self.container = CKContainer(identifier: "iCloud.com.invoicebuilder.app")
        self.privateDatabase = container.privateCloudDatabase
        self.publicDatabase = container.publicCloudDatabase
        
        setupAccountStatusMonitoring()
    }
    
    // MARK: - CloudStorageProvider Implementation
    
    public var isAuthenticated: Bool {
        get async {
            await checkAccountStatus()
            return accountStatus == .available
        }
    }
    
    public func authenticate() async throws {
        await checkAccountStatus()
        
        switch accountStatus {
        case .available:
            return // Already authenticated
        case .noAccount:
            throw iCloudError.noAccount
        case .restricted:
            throw iCloudError.restricted
        case .couldNotDetermine:
            throw iCloudError.couldNotDetermine
        case .temporarilyUnavailable:
            throw iCloudError.temporarilyUnavailable
        @unknown default:
            throw iCloudError.unknownAccountStatus
        }
    }
    
    public func signOut() async throws {
        // iCloud doesn't have a traditional sign-out mechanism
        // Users must sign out from Settings app
        clearError()
    }
    
    public func uploadData(_ data: Data, to path: String) async throws {
        try await ensureAuthenticated()
        
        do {
            let record = try createSyncDataRecord(data: data, path: path)
            let _ = try await privateDatabase.save(record)
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func downloadData(from path: String) async throws -> Data {
        try await ensureAuthenticated()
        
        do {
            let recordID = CKRecord.ID(recordName: pathToRecordName(path))
            let record = try await privateDatabase.record(for: recordID)
            
            guard let data = record["data"] as? Data else {
                throw iCloudError.invalidData
            }
            
            return data
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func deleteData(at path: String) async throws {
        try await ensureAuthenticated()
        
        do {
            let recordID = CKRecord.ID(recordName: pathToRecordName(path))
            let _ = try await privateDatabase.deleteRecord(withID: recordID)
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func listFiles(in directory: String) async throws -> [CloudFileInfo] {
        try await ensureAuthenticated()
        
        do {
            let predicate = NSPredicate(format: "path BEGINSWITH %@", directory)
            let query = CKQuery(recordType: RecordType.syncData, predicate: predicate)
            
            let results = try await privateDatabase.records(matching: query)
            var files: [CloudFileInfo] = []
            
            for (_, result) in results.matchResults {
                switch result {
                case .success(let record):
                    if let fileInfo = createFileInfo(from: record) {
                        files.append(fileInfo)
                    }
                case .failure:
                    continue // Skip failed records
                }
            }
            
            return files.sorted { $0.modifiedDate > $1.modifiedDate }
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func fileExists(at path: String) async throws -> Bool {
        try await ensureAuthenticated()
        
        do {
            let recordID = CKRecord.ID(recordName: pathToRecordName(path))
            let _ = try await privateDatabase.record(for: recordID)
            return true
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return false
            }
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func getFileInfo(at path: String) async throws -> CloudFileInfo? {
        try await ensureAuthenticated()
        
        do {
            let recordID = CKRecord.ID(recordName: pathToRecordName(path))
            let record = try await privateDatabase.record(for: recordID)
            return createFileInfo(from: record)
        } catch {
            if let ckError = error as? CKError, ckError.code == .unknownItem {
                return nil
            }
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    // MARK: - Batch Operations
    
    public func uploadBatch(_ items: [(path: String, data: Data)]) async throws {
        try await ensureAuthenticated()
        
        let records = try items.map { item in
            try createSyncDataRecord(data: item.data, path: item.path)
        }
        
        do {
            let _ = try await privateDatabase.modifyRecords(saving: records, deleting: [])
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func downloadBatch(paths: [String]) async throws -> [String: Data] {
        try await ensureAuthenticated()
        
        let recordIDs = paths.map { CKRecord.ID(recordName: pathToRecordName($0)) }
        
        do {
            let results = try await privateDatabase.records(for: recordIDs)
            var downloadedData: [String: Data] = [:]
            
            for (_, result) in results {
                switch result {
                case .success(let record):
                    if let path = record["path"] as? String,
                       let data = record["data"] as? Data {
                        downloadedData[path] = data
                    }
                case .failure:
                    continue // Skip failed records
                }
            }
            
            return downloadedData
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    // MARK: - Subscription Management
    
    public func subscribeToChanges() async throws {
        try await ensureAuthenticated()
        
        let subscription = CKQuerySubscription(
            recordType: RecordType.syncData,
            predicate: NSPredicate(value: true),
            subscriptionID: "InvoiceBuilderSyncSubscription",
            options: [.firesOnRecordCreation, .firesOnRecordUpdate, .firesOnRecordDeletion]
        )
        
        let notificationInfo = CKSubscription.NotificationInfo()
        notificationInfo.shouldSendContentAvailable = true
        subscription.notificationInfo = notificationInfo
        
        do {
            let _ = try await privateDatabase.save(subscription)
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    public func unsubscribeFromChanges() async throws {
        try await ensureAuthenticated()
        
        do {
            let subscriptions = try await privateDatabase.allSubscriptions()
            let syncSubscriptions = subscriptions.filter { subscription in
                if let querySubscription = subscription as? CKQuerySubscription {
                    return querySubscription.recordType == RecordType.syncData
                }
                return false
            }
            
            for subscription in syncSubscriptions {
                try await privateDatabase.deleteSubscription(withID: subscription.subscriptionID)
            }
        } catch {
            let iCloudError = mapCloudKitError(error)
            self.error = iCloudError
            throw iCloudError
        }
    }
    
    // MARK: - Error Handling
    
    public func clearError() {
        error = nil
    }
    
    // MARK: - Private Methods
    
    private func setupAccountStatusMonitoring() {
        // Monitor account status changes
        NotificationCenter.default
            .publisher(for: .CKAccountChanged)
            .sink { [weak self] _ in
                Task { @MainActor in
                    await self?.checkAccountStatus()
                }
            }
            .store(in: &cancellables)
    }
    
    @discardableResult
    private func checkAccountStatus() async -> CKAccountStatus {
        do {
            let status = try await container.accountStatus()
            accountStatus = status
            return status
        } catch {
            accountStatus = .couldNotDetermine
            self.error = mapCloudKitError(error)
            return .couldNotDetermine
        }
    }
    
    private func ensureAuthenticated() async throws {
        guard await isAuthenticated else {
            throw iCloudError.notAuthenticated
        }
    }
    
    private func createSyncDataRecord(data: Data, path: String) throws -> CKRecord {
        let recordName = pathToRecordName(path)
        let recordID = CKRecord.ID(recordName: recordName)
        let record = CKRecord(recordType: RecordType.syncData, recordID: recordID)
        
        record["path"] = path
        record["data"] = data
        record["size"] = Int64(data.count)
        record["checksum"] = generateChecksum(for: data)
        
        return record
    }
    
    private func createFileInfo(from record: CKRecord) -> CloudFileInfo? {
        guard let path = record["path"] as? String,
              let size = record["size"] as? Int64 else {
            return nil
        }
        
        let name = URL(fileURLWithPath: path).lastPathComponent
        let modifiedDate = record.modificationDate ?? Date()
        let checksum = record["checksum"] as? String
        
        return CloudFileInfo(
            path: path,
            name: name,
            size: size,
            modifiedDate: modifiedDate,
            checksum: checksum
        )
    }
    
    private func pathToRecordName(_ path: String) -> String {
        // Convert file path to valid CloudKit record name
        return path.replacingOccurrences(of: "/", with: "_")
                  .replacingOccurrences(of: ".", with: "-")
    }
    
    private func generateChecksum(for data: Data) -> String {
        return data.base64EncodedString().prefix(32).description
    }
    
    private func mapCloudKitError(_ error: Error) -> iCloudError {
        guard let ckError = error as? CKError else {
            return .unknownError(error.localizedDescription)
        }
        
        switch ckError.code {
        case .networkUnavailable, .networkFailure:
            return .networkUnavailable
        case .notAuthenticated:
            return .notAuthenticated
        case .quotaExceeded:
            return .quotaExceeded
        case .zoneBusy, .serviceUnavailable:
            return .serviceUnavailable
        case .requestRateLimited:
            return .rateLimited
        case .unknownItem:
            return .recordNotFound
        case .invalidArguments:
            return .invalidData
        case .permissionFailure:
            return .permissionDenied
        case .managedAccountRestricted:
            return .restricted
        default:
            return .unknownError(ckError.localizedDescription)
        }
    }
}

// MARK: - iCloud Error Types

public enum iCloudError: LocalizedError, Sendable {
    case noAccount
    case restricted
    case couldNotDetermine
    case temporarilyUnavailable
    case unknownAccountStatus
    case notAuthenticated
    case networkUnavailable
    case quotaExceeded
    case serviceUnavailable
    case rateLimited
    case recordNotFound
    case invalidData
    case permissionDenied
    case unknownError(String)
    
    public var errorDescription: String? {
        switch self {
        case .noAccount:
            return "No iCloud account configured. Please sign in to iCloud in Settings."
        case .restricted:
            return "iCloud access is restricted on this device."
        case .couldNotDetermine:
            return "Unable to determine iCloud account status."
        case .temporarilyUnavailable:
            return "iCloud is temporarily unavailable."
        case .unknownAccountStatus:
            return "Unknown iCloud account status."
        case .notAuthenticated:
            return "Not authenticated with iCloud."
        case .networkUnavailable:
            return "Network connection to iCloud is unavailable."
        case .quotaExceeded:
            return "iCloud storage quota exceeded."
        case .serviceUnavailable:
            return "iCloud service is currently unavailable."
        case .rateLimited:
            return "Too many requests to iCloud. Please try again later."
        case .recordNotFound:
            return "Requested data not found in iCloud."
        case .invalidData:
            return "Invalid data format for iCloud storage."
        case .permissionDenied:
            return "Permission denied for iCloud access."
        case .unknownError(let message):
            return "iCloud error: \(message)"
        }
    }
    
    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .serviceUnavailable, .rateLimited, .temporarilyUnavailable:
            return true
        case .noAccount, .restricted, .notAuthenticated, .quotaExceeded, .permissionDenied, .invalidData, .recordNotFound:
            return false
        case .couldNotDetermine, .unknownAccountStatus, .unknownError:
            return true
        }
    }
}

// MARK: - Extensions

extension CKAccountStatus {
    public var displayName: String {
        switch self {
        case .available:
            return "Available"
        case .noAccount:
            return "No Account"
        case .restricted:
            return "Restricted"
        case .couldNotDetermine:
            return "Unknown"
        case .temporarilyUnavailable:
            return "Temporarily Unavailable"
        @unknown default:
            return "Unknown"
        }
    }
}

// MARK: - CloudKit Extensions

extension CloudSyncError {
    init(from iCloudError: iCloudError) {
        switch iCloudError {
        case .noAccount, .notAuthenticated:
            self = .providerNotAuthenticated
        case .networkUnavailable:
            self = .networkUnavailable
        case .quotaExceeded:
            self = .quotaExceeded
        case .recordNotFound:
            self = .fileNotFound("iCloud record not found")
        case .invalidData:
            self = .invalidData
        case .permissionDenied, .restricted:
            self = .unauthorized
        default:
            self = .unknownError(iCloudError.localizedDescription)
        }
    }
}