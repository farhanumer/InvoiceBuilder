import Foundation

public struct Client: Sendable, Identifiable {
    public let id: UUID
    public var name: String
    public var email: String
    public var phone: String?
    public var address: Address?
    public var company: String?
    public var website: String?
    public var notes: String?
    public var createdDate: Date
    
    public init(
        id: UUID = UUID(),
        name: String,
        email: String,
        phone: String? = nil,
        address: Address? = nil,
        company: String? = nil,
        website: String? = nil,
        notes: String? = nil,
        createdDate: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.address = address
        self.company = company
        self.website = website
        self.notes = notes
        self.createdDate = createdDate
    }
}

public struct Address: Sendable {
    public var street: String
    public var city: String
    public var state: String?
    public var postalCode: String
    public var country: String
    
    public init(
        street: String,
        city: String,
        state: String? = nil,
        postalCode: String,
        country: String
    ) {
        self.street = street
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.country = country
    }
    
    public var formattedAddress: String {
        var components: [String] = [street, city]
        if let state = state {
            components.append(state)
        }
        components.append(postalCode)
        components.append(country)
        return components.joined(separator: ", ")
    }
}