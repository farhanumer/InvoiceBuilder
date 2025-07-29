import Foundation

public struct Client: Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var email: String
    public var phone: String?
    public var address: Address?
    public var company: String?
    public var website: String?
    public var taxNumber: String?
    public var avatarData: Data?
    public var notes: String?
    public var createdDate: Date
    public var updatedAt: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phone: String? = nil,
        address: Address? = nil,
        company: String? = nil,
        website: String? = nil,
        taxNumber: String? = nil,
        avatarData: Data? = nil,
        notes: String? = nil,
        createdDate: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.company = company
        self.website = website
        self.taxNumber = taxNumber
        self.avatarData = avatarData
        self.notes = notes
        self.createdDate = createdDate
        self.updatedAt = updatedAt
    }
    
    public init(from entity: ClientEntity) {
        self.id = entity.id
        self.name = entity.name
        self.email = entity.email
        self.phone = entity.phone
        self.address = entity.address != nil ? Address(from: entity.address!) : nil
        self.company = entity.company
        self.website = entity.website
        self.taxNumber = entity.taxNumber
        self.avatarData = entity.avatarData
        self.notes = entity.notes
        self.createdDate = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
}

public struct Address: Sendable {
    public var street: String
    public var city: String
    public var state: String
    public var postalCode: String
    public var country: String
    
    public init(
        street: String,
        city: String,
        state: String,
        postalCode: String,
        country: String
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }
    
    public init(from entity: AddressEntity) {
        self.street = entity.street
        self.city = entity.city
        self.state = entity.state
        self.postalCode = entity.postalCode
        self.country = entity.country
    }
    
    public var formattedAddress: String {
        var components: [String] = [street, city]
        if !state.isEmpty {
            components.append(state)
        }
        components.append(postalCode)
        components.append(country)
        return components.joined(separator: ", ")
    }
}