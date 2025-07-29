import Foundation
import SwiftData

@Model
public final class ClientEntity {
    public var id: UUID
    public var name: String
    public var email: String
    public var phone: String?
    public var company: String?
    public var website: String?
    public var taxNumber: String?
    public var address: AddressEntity?
    public var avatarData: Data?
    public var notes: String?
    public var createdAt: Date
    public var updatedAt: Date
    
    // Relationships
    @Relationship(inverse: \InvoiceEntity.client) public var invoices: [InvoiceEntity]
    
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phone: String? = nil,
        company: String? = nil,
        website: String? = nil,
        taxNumber: String? = nil,
        address: AddressEntity? = nil,
        avatarData: Data? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.company = company
        self.website = website
        self.taxNumber = taxNumber
        self.address = address
        self.avatarData = avatarData
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
        self.invoices = []
    }
}

@Model
public final class AddressEntity {
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
}