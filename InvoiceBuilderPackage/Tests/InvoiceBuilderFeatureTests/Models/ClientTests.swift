import Testing
import Foundation
@testable import InvoiceBuilderFeature

@Suite("Client Model Tests")
struct ClientTests {
    
    @Test("Client initialization with required fields")
    func testClientInitialization() async throws {
        let client = Client(
            name: "John Doe",
            email: "john@example.com"
        )
        
        #expect(client.name == "John Doe")
        #expect(client.email == "john@example.com")
        #expect(client.phone == nil)
        #expect(client.company == nil)
        #expect(client.address == nil)
    }
    
    @Test("Client initialization with all fields")
    func testClientInitializationComplete() async throws {
        let address = Address(
            street: "123 Main St",
            city: "Anytown",
            state: "CA",
            postalCode: "12345",
            country: "USA"
        )
        
        let client = Client(
            name: "Jane Smith",
            email: "jane@company.com",
            phone: "+1234567890",
            address: address,
            company: "Smith Corp",
            website: "https://smithcorp.com",
            taxNumber: "TAX123456",
            notes: "Important client"
        )
        
        #expect(client.name == "Jane Smith")
        #expect(client.email == "jane@company.com")
        #expect(client.phone == "+1234567890")
        #expect(client.company == "Smith Corp")
        #expect(client.website == "https://smithcorp.com")
        #expect(client.taxNumber == "TAX123456")
        #expect(client.notes == "Important client")
        #expect(client.address?.street == "123 Main St")
        #expect(client.address?.city == "Anytown")
    }
    
    @Test("Client from entity initialization")
    func testClientFromEntity() async throws {
        let addressEntity = AddressEntity(
            street: "456 Oak Ave",
            city: "TestCity",
            state: "NY",
            postalCode: "67890",
            country: "USA"
        )
        
        let clientEntity = ClientEntity(
            name: "Test Entity Client",
            email: "entity@test.com",
            phone: "+9876543210",
            company: "Test Entity Corp",
            website: "https://testentity.com",
            taxNumber: "ENTITY123",
            address: addressEntity,
            notes: "Entity client notes"
        )
        
        let client = Client(from: clientEntity)
        
        #expect(client.name == "Test Entity Client")
        #expect(client.email == "entity@test.com")
        #expect(client.phone == "+9876543210")
        #expect(client.company == "Test Entity Corp")
        #expect(client.website == "https://testentity.com")
        #expect(client.taxNumber == "ENTITY123")
        #expect(client.notes == "Entity client notes")
        #expect(client.address?.street == "456 Oak Ave")
        #expect(client.address?.formattedAddress.contains("TestCity") == true)
    }
    
    @Test("Address formatted string")
    func testAddressFormatting() async throws {
        let address = Address(
            street: "789 Pine St",
            city: "Springfield",
            state: "IL",
            postalCode: "62701",
            country: "USA"
        )
        
        let formatted = address.formattedAddress
        let expectedComponents = ["789 Pine St", "Springfield", "IL", "62701", "USA"]
        
        for component in expectedComponents {
            #expect(formatted.contains(component))
        }
    }
    
    @Test("Address from entity")
    func testAddressFromEntity() async throws {
        let addressEntity = AddressEntity(
            street: "321 Elm St",
            city: "Riverside",
            state: "CA",
            postalCode: "92501",
            country: "USA"
        )
        
        let address = Address(from: addressEntity)
        
        #expect(address.street == "321 Elm St")
        #expect(address.city == "Riverside")
        #expect(address.state == "CA")
        #expect(address.postalCode == "92501")
        #expect(address.country == "USA")
    }
}