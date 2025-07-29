import SwiftUI
import SwiftData

@Observable
@MainActor
public final class ClientService {
    public var clients: [Client] = []
    public var isLoading: Bool = false
    
    private let dataStack: SwiftDataStack
    
    public init(dataStack: SwiftDataStack = .shared) {
        self.dataStack = dataStack
    }
    
    public func loadClients() async {
        isLoading = true
        defer { isLoading = false }
        
        do {
            let entities = try dataStack.fetchClients()
            clients = entities.map { Client(from: $0) }
        } catch {
            print("Failed to load clients: \(error)")
            clients = []
        }
    }
    
    public func createClient(_ client: Client) async throws {
        let entity = ClientEntity(
            name: client.name,
            email: client.email,  
            phone: client.phone,
            company: client.company,
            website: client.website,
            taxNumber: client.taxNumber,
            avatarData: client.avatarData,
            notes: client.notes
        )
        
        // Create address entity if provided
        if let address = client.address {
            let addressEntity = AddressEntity(
                street: address.street,
                city: address.city,
                state: address.state,
                postalCode: address.postalCode,
                country: address.country
            )
            entity.address = addressEntity
        }
        
        dataStack.insert(entity)
        try dataStack.save()
        
        // Reload clients
        await loadClients()
    }
    
    public func updateClient(_ client: Client) async throws {
        guard let entity = try dataStack.fetchClient(by: client.id) else {
            throw ClientServiceError.clientNotFound
        }
        
        entity.name = client.name
        entity.email = client.email
        entity.phone = client.phone
        entity.company = client.company
        entity.website = client.website
        entity.taxNumber = client.taxNumber
        entity.avatarData = client.avatarData
        entity.notes = client.notes
        entity.updatedAt = Date()
        
        // Update address
        if let address = client.address {
            if entity.address == nil {
                entity.address = AddressEntity(
                    street: address.street,
                    city: address.city,
                    state: address.state,
                    postalCode: address.postalCode,
                    country: address.country
                )
            } else {
                entity.address?.street = address.street
                entity.address?.city = address.city
                entity.address?.state = address.state
                entity.address?.postalCode = address.postalCode
                entity.address?.country = address.country
            }
        } else {
            entity.address = nil
        }
        
        try dataStack.save()
        
        // Reload clients
        await loadClients()
    }
    
    public func deleteClient(_ client: Client) async throws {
        guard let entity = try dataStack.fetchClient(by: client.id) else {
            throw ClientServiceError.clientNotFound
        }
        
        // Check if client has invoices
        if !entity.invoices.isEmpty {
            throw ClientServiceError.clientHasInvoices
        }
        
        dataStack.delete(entity)
        try dataStack.save()
        
        // Remove from local array
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

public enum ClientServiceError: Error, LocalizedError {
    case clientNotFound
    case clientHasInvoices
    case invalidData
    case saveFailed
    
    public var errorDescription: String? {
        switch self {
        case .clientNotFound:
            return "Client not found"
        case .clientHasInvoices:
            return "Cannot delete client with existing invoices"
        case .invalidData:
            return "Invalid client data"
        case .saveFailed:
            return "Failed to save client"
        }
    }
}