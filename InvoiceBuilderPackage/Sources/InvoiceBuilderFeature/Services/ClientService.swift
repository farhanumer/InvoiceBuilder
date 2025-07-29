import SwiftUI

@Observable
@MainActor
public final class ClientService {
    public var clients: [Client] = []
    public var isLoading: Bool = false
    
    public init() {}
    
    public func loadClients() async {
        isLoading = true
        defer { isLoading = false }
        
        // TODO: Load from persistent storage
        // Simulate network delay
        try? await Task.sleep(for: .seconds(1))
        
        // Mock data for development
        clients = []
    }
    
    public func createClient(_ client: Client) async throws {
        // TODO: Save to persistent storage
        clients.append(client)
    }
    
    public func updateClient(_ client: Client) async throws {
        // TODO: Update in persistent storage
        if let index = clients.firstIndex(where: { $0.id == client.id }) {
            clients[index] = client
        }
    }
    
    public func deleteClient(_ client: Client) async throws {
        // TODO: Delete from persistent storage
        clients.removeAll { $0.id == client.id }
    }
    
    public func searchClients(_ query: String) -> [Client] {
        if query.isEmpty {
            return clients
        }
        return clients.filter { client in
            client.name.localizedCaseInsensitiveContains(query) ||
            client.email.localizedCaseInsensitiveContains(query) ||
            client.company?.localizedCaseInsensitiveContains(query) == true
        }
    }
}