import SwiftUI
import UIKit

public struct ClientPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let clients: [Client]
    let onClientSelected: (Client) -> Void
    
    @State private var searchText = ""
    
    private var filteredClients: [Client] {
        if searchText.isEmpty {
            return clients.sorted { $0.name < $1.name }
        } else {
            return clients.filter { client in
                client.name.localizedCaseInsensitiveContains(searchText) ||
                client.email.localizedCaseInsensitiveContains(searchText) ||
                (client.company?.localizedCaseInsensitiveContains(searchText) ?? false)
            }.sorted { $0.name < $1.name }
        }
    }
    
    public init(clients: [Client], onClientSelected: @escaping (Client) -> Void) {
        self.clients = clients
        self.onClientSelected = onClientSelected
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search Bar
                SearchBar(text: $searchText)
                    .padding()
                    .background(.regularMaterial)
                
                // Client List
                if filteredClients.isEmpty {
                    emptyStateView
                } else {
                    List(filteredClients) { client in
                        ClientPickerRow(client: client) {
                            onClientSelected(client)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Select Client")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "person.2.slash")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Clients Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if searchText.isEmpty {
                Text("You haven't added any clients yet.\nAdd your first client to get started.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Text("No clients match your search.\nTry a different search term.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ClientPickerRow: View {
    let client: Client
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Avatar
                Group {
                    if let avatarData = client.avatarData, let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Circle()
                            .fill(.gray.opacity(0.3))
                            .overlay {
                                Text(String(client.name.prefix(1)))
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .frame(width: 44, height: 44)
                .clipShape(Circle())
                
                // Client Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(client.name)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if let company = client.company, !company.isEmpty {
                            Text(company)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(.blue.opacity(0.1))
                                .foregroundStyle(.blue)
                                .clipShape(Capsule())
                        }
                    }
                    
                    Text(client.email)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    if let phone = client.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search clients", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

#Preview {
    ClientPickerView(clients: [
        Client(
            name: "John Doe",
            email: "john@example.com",
            phone: "+1 234 567 8900",
            company: "ACME Corp"
        ),
        Client(
            name: "Jane Smith",
            email: "jane@techstartup.com",
            phone: "+1 555 123 4567",
            company: "Tech Startup"
        )
    ]) { client in
        print("Selected: \(client.name)")
    }
}