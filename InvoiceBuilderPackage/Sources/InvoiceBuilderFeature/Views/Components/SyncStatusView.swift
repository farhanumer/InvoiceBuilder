import SwiftUI

public struct SyncStatusView: View {
    @Environment(CloudSyncService.self) private var syncService
    
    public init() {}
    
    public var body: some View {
        HStack(spacing: 6) {
            statusIcon
            
            VStack(alignment: .leading, spacing: 2) {
                Text(syncService.currentStatus.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                if let lastSync = syncService.lastSyncDate {
                    Text("Last: \(lastSync, formatter: relativeDateFormatter)")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            
            if syncService.currentStatus == .syncing {
                ProgressView()
                    .scaleEffect(0.8)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(backgroundStyle, in: RoundedRectangle(cornerRadius: 6))
    }
    
    @ViewBuilder
    private var statusIcon: some View {
        Image(systemName: iconName)
            .foregroundStyle(iconColor)
            .font(.caption)
            .fontWeight(.medium)
    }
    
    private var iconName: String {
        switch syncService.currentStatus {
        case .idle:
            return "checkmark.circle.fill"
        case .syncing, .uploading, .downloading:
            return "arrow.triangle.2.circlepath"
        case .error:
            return "exclamationmark.triangle.fill"
        case .conflict:
            return "exclamationmark.octagon.fill"
        }
    }
    
    private var iconColor: Color {
        switch syncService.currentStatus {
        case .idle:
            return .green
        case .syncing, .uploading, .downloading:
            return .blue
        case .error:
            return .red
        case .conflict:
            return .orange
        }
    }
    
    private var backgroundStyle: some ShapeStyle {
        switch syncService.currentStatus {
        case .idle:
            return AnyShapeStyle(.green.opacity(0.1))
        case .syncing, .uploading, .downloading:
            return AnyShapeStyle(.blue.opacity(0.1))
        case .error:
            return AnyShapeStyle(.red.opacity(0.1))
        case .conflict:
            return AnyShapeStyle(.orange.opacity(0.1))
        }
    }
}

public struct SyncStatusButton: View {
    @Environment(CloudSyncService.self) private var syncService
    @State private var showingSyncDetails = false
    
    public init() {}
    
    public var body: some View {
        Button {
            if syncService.error != nil {
                Task {
                    try? await syncService.retrySync()
                }
            } else {
                showingSyncDetails = true
            }
        } label: {
            HStack(spacing: 4) {
                Image(systemName: iconName)
                    .foregroundStyle(iconColor)
                
                if syncService.queuedItemsCount > 0 {
                    Text("\(syncService.queuedItemsCount)")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(.red, in: Capsule())
                }
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingSyncDetails) {
            SyncDetailsView()
        }
    }
    
    private var iconName: String {
        switch syncService.currentStatus {
        case .idle:
            return "icloud"
        case .syncing, .uploading, .downloading:
            return "icloud.and.arrow.up"
        case .error:
            return "icloud.slash"
        case .conflict:
            return "icloud.slash"
        }
    }
    
    private var iconColor: Color {
        switch syncService.currentStatus {
        case .idle:
            return .primary
        case .syncing, .uploading, .downloading:
            return .blue
        case .error:
            return .red
        case .conflict:
            return .orange
        }
    }
}

public struct SyncDetailsView: View {
    @Environment(CloudSyncService.self) private var syncService
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            List {
                Section {
                    SyncStatusRow()
                    NetworkStatusRow()
                    ProviderStatusRow()
                    QueueStatusRow()
                } header: {
                    Text("Sync Status")
                }
                
                if !syncService.conflictItems.isEmpty {
                    Section {
                        ForEach(syncService.conflictItems) { conflict in
                            ConflictRowView(conflict: conflict)
                        }
                    } header: {
                        Text("Conflicts")
                    }
                }
                
                if let error = syncService.error {
                    Section {
                        ErrorRowView(error: error)
                    } header: {
                        Text("Error")
                    }
                }
                
                Section {
                    Button("Force Sync") {
                        Task {
                            try? await syncService.syncData()
                        }
                    }
                    .disabled(syncService.currentStatus == .syncing)
                    
                    Button("Clear Queue") {
                        syncService.clearSyncQueue()
                    }
                    .disabled(syncService.queuedItemsCount == 0)
                    
                    if syncService.error != nil {
                        Button("Retry") {
                            Task {
                                try? await syncService.retrySync()
                            }
                        }
                    }
                } header: {
                    Text("Actions")
                }
            }
            .navigationTitle("Sync Details")
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
        }
    }
}

private struct SyncStatusRow: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        HStack {
            Label("Status", systemImage: "arrow.triangle.2.circlepath")
            
            Spacer()
            
            Text(syncService.currentStatus.displayName)
                .foregroundStyle(.secondary)
        }
    }
}

private struct NetworkStatusRow: View {
    @Environment(NetworkMonitor.self) private var networkMonitor
    
    var body: some View {
        HStack {
            Label("Network", systemImage: "wifi")
            
            Spacer()
            
            Text(networkMonitor.isConnected ? "Connected" : "Disconnected")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ProviderStatusRow: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        HStack {
            Label("Provider", systemImage: "icloud")
            
            Spacer()
            
            Text(syncService.providerName ?? "None")
                .foregroundStyle(.secondary)
        }
    }
}

private struct QueueStatusRow: View {
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        HStack {
            Label("Queue", systemImage: "tray")
            
            Spacer()
            
            Text("\(syncService.queuedItemsCount) items")
                .foregroundStyle(.secondary)
        }
    }
}

private struct ConflictRowView: View {
    let conflict: SyncConflictItem
    @Environment(CloudSyncService.self) private var syncService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(conflict.filePath)
                .font(.caption)
                .fontWeight(.medium)
            
            Text("Local: \(conflict.localModifiedDate, formatter: dateFormatter) • Remote: \(conflict.remoteModifiedDate, formatter: dateFormatter)")
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            HStack {
                Button("Use Local") {
                    Task {
                        try? await syncService.resolveConflict(conflict, resolution: .useLocal)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Button("Use Remote") {
                    Task {
                        try? await syncService.resolveConflict(conflict, resolution: .useRemote)
                    }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(.vertical, 2)
    }
}

private struct ErrorRowView: View {
    let error: CloudSyncError
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sync Error")
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.red)
            
            Text(error.localizedDescription)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }
}

// MARK: - Formatters

private let relativeDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.doesRelativeDateFormatting = true
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}()

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}()

// MARK: - Preview

#Preview {
    VStack(spacing: 20) {
        SyncStatusView()
        SyncStatusButton()
    }
    .padding()
    .environment(CloudSyncService.shared)
    .environment(NetworkMonitor.shared)
}