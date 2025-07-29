import Foundation
import SwiftData

@Model
public final class InvoiceTemplateEntity {
    public var id: UUID
    public var name: String
    public var displayName: String
    public var templateDescription: String?
    public var isDefault: Bool
    public var isCustom: Bool
    public var primaryColor: String
    public var secondaryColor: String
    public var accentColor: String
    public var fontFamily: String
    public var fontSize: Int
    public var logoPosition: String
    public var headerLayout: String
    public var footerLayout: String
    public var showTaxColumn: Bool
    public var showDiscountColumn: Bool
    public var showNotesSection: Bool
    public var showTermsSection: Bool
    public var customCSS: String?
    public var previewImageData: Data?
    public var createdAt: Date
    public var updatedAt: Date
    
    // Relationships
    @Relationship public var businessProfile: BusinessProfileEntity?
    @Relationship(inverse: \InvoiceEntity.template) public var invoices: [InvoiceEntity]
    
    public init(
        id: UUID = UUID(),
        name: String,
        displayName: String,
        templateDescription: String? = nil,
        isDefault: Bool = false,
        isCustom: Bool = false,
        primaryColor: String = "#000000",
        secondaryColor: String = "#666666",
        accentColor: String = "#007AFF",
        fontFamily: String = "System",
        fontSize: Int = 12,
        logoPosition: String = "top-left",
        headerLayout: String = "standard",
        footerLayout: String = "standard",
        showTaxColumn: Bool = true,
        showDiscountColumn: Bool = false,
        showNotesSection: Bool = true,
        showTermsSection: Bool = true,
        customCSS: String? = nil,
        previewImageData: Data? = nil
    ) {
        self.id = id
        self.name = name
        self.displayName = displayName
        self.templateDescription = templateDescription
        self.isDefault = isDefault
        self.isCustom = isCustom
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.logoPosition = logoPosition
        self.headerLayout = headerLayout
        self.footerLayout = footerLayout
        self.showTaxColumn = showTaxColumn
        self.showDiscountColumn = showDiscountColumn
        self.showNotesSection = showNotesSection
        self.showTermsSection = showTermsSection
        self.customCSS = customCSS
        self.previewImageData = previewImageData
        self.createdAt = Date()
        self.updatedAt = Date()
        self.invoices = []
    }
}