import Foundation
import SwiftData

@Model
public final class ServiceItemEntity {
    public var id: UUID
    public var name: String
    public var itemDescription: String?
    public var defaultRate: Decimal
    public var category: String?
    public var iconName: String?
    public var isActive: Bool
    public var createdAt: Date
    public var updatedAt: Date
    public var sortOrder: Int
    
    // Relationships
    @Relationship 
    public var businessProfile: BusinessProfileEntity?
    
    public init(
        id: UUID = UUID(),
        name: String,
        itemDescription: String? = nil,
        defaultRate: Decimal,
        category: String? = nil,
        iconName: String? = nil,
        isActive: Bool = true,
        sortOrder: Int = 0
    ) {
        self.id = id
        self.name = name
        self.itemDescription = itemDescription
        self.defaultRate = defaultRate
        self.category = category
        self.iconName = iconName
        self.isActive = isActive
        self.sortOrder = sortOrder
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}