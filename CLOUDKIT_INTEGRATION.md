# CloudKit Integration Guide

This document explains how to integrate the iCloud/CloudKit sync functionality into your Invoice Builder app.

## Overview

The CloudKit integration provides:
- ✅ **Abstracted Cloud Sync Service** - Works with multiple cloud providers
- ✅ **iCloud/CloudKit Provider** - Primary sync implementation
- ✅ **Automatic Sync Queue** - Offline-first with retry logic
- ✅ **Conflict Resolution** - Handle sync conflicts gracefully
- ✅ **Network Monitoring** - Auto-sync when online
- ✅ **Push Notifications** - Real-time sync updates
- ✅ **Status UI Components** - User-friendly sync status

## Quick Start

### 1. Add CloudSync Environment to Your App

In your main app view or ContentView, add the cloud sync environment:

```swift
import SwiftUI
import InvoiceBuilderFeature

@main
struct InvoiceBuilderApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .withCloudSyncEnvironment() // Add this line
        }
    }
}
```

### 2. Display Sync Status in Your UI

Add sync status components to your main views:

```swift
struct MainView: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        NavigationStack {
            VStack {
                // Show CloudKit setup banner if needed
                CloudKitStatusBanner()
                
                // Your main content here
                MyMainContent()
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    SyncStatusButton()
                }
            }
        }
    }
}
```

### 3. Make Your Models Syncable

Implement the `SyncableEntity` protocol on your SwiftData models:

```swift
import Foundation
import SwiftData
import InvoiceBuilderFeature

@Model
public final class Invoice: SyncableEntity {
    public var id: UUID = UUID()
    public var lastModified: Date = Date()
    public var syncStatus: SyncEntityStatus = .pending
    
    // Your existing properties...
    public var invoiceNumber: String = ""
    public var clientName: String = ""
    // ... etc
    
    // MARK: - SyncableEntity Implementation
    
    public static var syncEntityType: String { "Invoice" }
    
    public func toSyncData() throws -> Data {
        let syncData = InvoiceSyncData(
            id: id,
            invoiceNumber: invoiceNumber,
            clientName: clientName,
            lastModified: lastModified
            // Add other properties...
        )
        return try JSONEncoder().encode(syncData)
    }
    
    public func updateFromSyncData(_ data: Data) throws {
        let syncData = try JSONDecoder().decode(InvoiceSyncData.self, from: data)
        
        // Update properties from sync data
        self.invoiceNumber = syncData.invoiceNumber
        self.clientName = syncData.clientName
        self.lastModified = syncData.lastModified
        // Update other properties...
    }
}

// Codable sync data structure
private struct InvoiceSyncData: Codable {
    let id: UUID
    let invoiceNumber: String
    let clientName: String
    let lastModified: Date
    // Add other properties...
}
```

### 4. Trigger Sync When Data Changes

Use the auto-sync helper when your data changes:

```swift
struct InvoiceEditorView: View {
    @Bindable var invoice: Invoice
    @Environment(\.modelContext) private var context
    
    var body: some View {
        Form {
            TextField("Invoice Number", text: $invoice.invoiceNumber)
            TextField("Client Name", text: $invoice.clientName)
        }
        .onSubmit {
            saveInvoice()
        }
    }
    
    private func saveInvoice() {
        do {
            // Save to local database
            try context.save()
            
            // Queue for sync
            AutoSyncHelper.triggerSync(
                for: invoice,
                operation: .update,
                priority: .normal
            )
        } catch {
            print("Save failed: \(error)")
        }
    }
}
```

## Advanced Usage

### Manual Sync Control

```swift
@Environment(CloudSyncService.self) private var syncService

// Force sync all pending items
Task {
    try await syncService.syncData()
}

// Queue specific item for sync
syncService.queueSync(
    operation: .create,
    entityType: "Invoice",
    entityId: invoice.id,
    data: invoiceData,
    priority: .high
)

// Check sync status
if syncService.currentStatus == .syncing {
    // Show loading indicator
}
```

### Authentication Control

```swift
// Check if user is authenticated
let setupService = CloudKitSetupService.shared
let accountInfo = await setupService.getAccountStatus()

if !accountInfo.canSync {
    // Show setup screen
    showingCloudKitSetup = true
}

// Authenticate manually
try await setupService.authenticateIfNeeded()
```

### Conflict Resolution

The system automatically detects conflicts and provides UI for resolution:

```swift
@Environment(CloudSyncService.self) private var syncService

// Check for conflicts
if !syncService.conflictItems.isEmpty {
    // Show conflict resolution UI
    showingConflicts = true
}

// Resolve a conflict programmatically
try await syncService.resolveConflict(
    conflict,
    resolution: .useLocal // or .useRemote, .merge
)
```

## CloudKit Container Setup

**Important**: Before using in production, you need to:

1. **Create CloudKit Container**:
   - Open your project in Xcode
   - Go to Signing & Capabilities
   - Add CloudKit capability
   - Create container: `iCloud.com.invoicebuilder.app`

2. **Configure CloudKit Schema**:
   - Open CloudKit Console
   - Create Record Type: `SyncData`
   - Add fields:
     - `path` (String)
     - `data` (Bytes)
     - `size` (Int64)
     - `checksum` (String)

3. **Deploy to Production**:
   - Test in Development environment
   - Deploy schema to Production when ready

## Entitlements

The following entitlements are already configured in `Config/InvoiceBuilder.entitlements`:

```xml
<!-- CloudKit Services -->
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>

<!-- CloudKit Containers -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.invoicebuilder.app</string>
</array>

<!-- Push Notifications -->
<key>aps-environment</key>
<string>development</string>

<!-- Background App Refresh for Sync -->
<key>com.apple.developer.background-modes</key>
<array>
    <string>background-processing</string>
    <string>remote-notification</string>
</array>
```

## Testing

Use the `CloudKitDemoView` to test the integration:

```swift
struct TestView: View {
    var body: some View {
        CloudKitDemoView()
            .withCloudSyncEnvironment()
    }
}
```

## Troubleshooting

### Common Issues

1. **"No iCloud account"**: User needs to sign into iCloud in Settings
2. **"Restricted"**: Check parental controls or device restrictions
3. **"Network unavailable"**: Items are queued and will sync when online
4. **"Quota exceeded"**: User needs more iCloud storage

### Debug Information

```swift
// Check account status
let accountInfo = await CloudKitSetupService.shared.getAccountStatus()
print("Can sync: \(accountInfo.canSync)")
print("Status: \(accountInfo.displayMessage)")

// Check sync queue
let queueCount = syncService.queuedItemsCount
print("Queued items: \(queueCount)")

// Check network status
print("Network: \(networkMonitor.isConnected)")
```

## Next Steps

After integrating basic sync:

1. **Add More Providers**: Implement Dropbox, Google Drive providers
2. **Background Sync**: Handle background app refresh
3. **Conflict UI**: Create custom conflict resolution screens
4. **Sync Analytics**: Track sync performance and errors
5. **Selective Sync**: Allow users to choose what to sync

## Files Structure

```
InvoiceBuilderPackage/Sources/InvoiceBuilderFeature/
├── Services/
│   ├── CloudSyncService.swift          # Main sync service
│   └── CloudKit/
│       ├── iCloudProvider.swift        # CloudKit implementation
│       └── CloudKitSetupService.swift  # Setup and configuration
├── Utils/
│   ├── NetworkMonitor.swift           # Network connectivity
│   └── SyncableEntity.swift           # Entity sync protocol
├── Views/Components/
│   ├── SyncStatusView.swift           # Sync status UI
│   └── CloudKitDemoView.swift         # Demo and testing
└── Extensions/
    └── Environment+CloudSync.swift    # SwiftUI integration
```

For complete implementation examples, see the demo view and existing service files.