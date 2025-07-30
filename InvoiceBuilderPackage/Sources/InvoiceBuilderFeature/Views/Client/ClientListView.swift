import SwiftUI
import SwiftData

public struct ClientListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var clients: [ClientEntity]
    
    @State private var searchText = ""
    @State private var showingAddClient = false
    @State private var selectedClient: Client?
    @State private var showingClientDetail = false
    @State private var sortOrder: SortOrder = .name
    @State private var isAscending = true
    
    private var filteredClients: [Client] {
        let clientModels = clients.map { Client(from: $0) }
        let filtered = searchText.isEmpty ? clientModels : clientModels.filter { client in
            client.name.localizedCaseInsensitiveContains(searchText) ||
            client.email.localizedCaseInsensitiveContains(searchText) ||
            client.company?.localizedCaseInsensitiveContains(searchText) == true
        }
        
        return filtered.sorted { client1, client2 in
            let result: Bool
            switch sortOrder {
            case .name:
                result = client1.name.localizedCaseInsensitiveCompare(client2.name) == .orderedAscending
            case .company:
                let company1 = client1.company ?? ""
                let company2 = client2.company ?? ""
                result = company1.localizedCaseInsensitiveCompare(company2) == .orderedAscending
            case .dateAdded:
                result = client1.createdDate < client2.createdDate
            case .lastUpdated:
                result = client1.updatedAt < client2.updatedAt
            }
            return isAscending ? result : !result
        }
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if clients.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else {
                    clientListContent
                }
            }
            .navigationTitle("Clients")
            .searchable(text: $searchText, prompt: "Search clients...")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    sortMenu
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddClient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .navigation) {
                    sortMenu
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddClient = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddClient) {
                ClientDetailView()
            }
            .sheet(item: $selectedClient) { client in
                ClientDetailView(client: client)
            }
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "person.2.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("No Clients Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Add your first client to start building your client list")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddClient = true
            } label: {
                Label("Add First Client", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var clientListContent: some View {
        if filteredClients.isEmpty && !searchText.isEmpty {
            noSearchResultsView
        } else {
            List {
                ForEach(filteredClients) { client in
                    ClientRowView(client: client) {
                        selectedClient = client
                    }
                }
                .onDelete(perform: deleteClients)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.sidebar)
            #endif
        }
    }
    
    @ViewBuilder
    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 4) {
                Text("No Results")
                    .font(.headline)
                
                Text("No clients match \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var sortMenu: some View {
        Menu {
            Section("Sort by") {
                Button {
                    setSortOrder(.name)
                } label: {
                    Label("Name", systemImage: sortOrder == .name ? "checkmark" : "")
                }
                
                Button {
                    setSortOrder(.company)
                } label: {
                    Label("Company", systemImage: sortOrder == .company ? "checkmark" : "")
                }
                
                Button {
                    setSortOrder(.dateAdded)
                } label: {
                    Label("Date Added", systemImage: sortOrder == .dateAdded ? "checkmark" : "")
                }
                
                Button {
                    setSortOrder(.lastUpdated)
                } label: {
                    Label("Last Updated", systemImage: sortOrder == .lastUpdated ? "checkmark" : "")
                }
            }
            
            Divider()
            
            Button {
                isAscending.toggle()
            } label: {
                Label(
                    isAscending ? "Ascending" : "Descending",
                    systemImage: isAscending ? "arrow.up" : "arrow.down"
                )
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
    
    // MARK: - Methods
    
    private func setSortOrder(_ order: SortOrder) {
        if sortOrder == order {
            isAscending.toggle()
        } else {
            sortOrder = order
            isAscending = true
        }
    }
    
    private func deleteClients(at offsets: IndexSet) {
        for index in offsets {
            let client = filteredClients[index]
            if let clientEntity = clients.first(where: { $0.id == client.id }) {
                modelContext.delete(clientEntity)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete clients: \(error)")
        }
    }
}

// MARK: - Supporting Types

private enum SortOrder {
    case name
    case company
    case dateAdded
    case lastUpdated
}

// MARK: - Client Row View

private struct ClientRowView: View {
    let client: Client
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                ClientAvatarView(
                    avatarData: client.avatarData,
                    name: client.name,
                    size: 44
                )
                
                // Client Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let company = client.company, !company.isEmpty {
                        Text(company)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(client.email)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                // Status indicators
                VStack(alignment: .trailing, spacing: 4) {
                    if let phone = client.phone, !phone.isEmpty {
                        Image(systemName: "phone.fill")
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                    
                    if client.address != nil {
                        Image(systemName: "location.fill")
                            .font(.caption)
                            .foregroundStyle(.blue)
                    }
                    
                    Text(client.createdDate, style: .date)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Client Avatar View

private struct ClientAvatarView: View {
    let avatarData: Data?
    let name: String
    let size: CGFloat
    
    var body: some View {
        Group {
            if let avatarData = avatarData, let image = loadImage(from: avatarData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Fallback to initials
                Text(nameInitials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(avatarColor)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var nameInitials: String {
        let components = name.components(separatedBy: .whitespaces)
        let initials = components.compactMap { $0.first?.uppercased() }
        return String(initials.prefix(2).joined())
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo, .teal, .cyan]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    private func loadImage(from data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIKit.UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = AppKit.NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}


#Preview {
    ClientListView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}