import Foundation

public struct InvoiceTemplate: Sendable, Identifiable {
    public let id: UUID
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
    public var logoPosition: LogoPosition
    public var headerLayout: HeaderLayout
    public var footerLayout: FooterLayout
    public var showTaxColumn: Bool
    public var showDiscountColumn: Bool
    public var showNotesSection: Bool
    public var showTermsSection: Bool
    public var customCSS: String?
    public var previewImageData: Data?
    public var createdAt: Date
    public var updatedAt: Date
    
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
        logoPosition: LogoPosition = .topLeft,
        headerLayout: HeaderLayout = .standard,
        footerLayout: FooterLayout = .standard,
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
    }
    
    public init(from entity: InvoiceTemplateEntity) {
        self.id = entity.id
        self.name = entity.name
        self.displayName = entity.displayName
        self.templateDescription = entity.templateDescription
        self.isDefault = entity.isDefault
        self.isCustom = entity.isCustom
        self.primaryColor = entity.primaryColor
        self.secondaryColor = entity.secondaryColor
        self.accentColor = entity.accentColor
        self.fontFamily = entity.fontFamily
        self.fontSize = entity.fontSize
        self.logoPosition = LogoPosition(rawValue: entity.logoPosition) ?? .topLeft
        self.headerLayout = HeaderLayout(rawValue: entity.headerLayout) ?? .standard
        self.footerLayout = FooterLayout(rawValue: entity.footerLayout) ?? .standard
        self.showTaxColumn = entity.showTaxColumn
        self.showDiscountColumn = entity.showDiscountColumn
        self.showNotesSection = entity.showNotesSection
        self.showTermsSection = entity.showTermsSection
        self.customCSS = entity.customCSS
        self.previewImageData = entity.previewImageData
        self.createdAt = entity.createdAt
        self.updatedAt = entity.updatedAt
    }
}

public enum LogoPosition: String, CaseIterable, Sendable {
    case topLeft = "top-left"
    case topCenter = "top-center"
    case topRight = "top-right"
    case bottomLeft = "bottom-left"
    case bottomCenter = "bottom-center"
    case bottomRight = "bottom-right"
    case hidden = "hidden"
    
    public var displayName: String {
        switch self {
        case .topLeft: return "Top Left"
        case .topCenter: return "Top Center"
        case .topRight: return "Top Right"
        case .bottomLeft: return "Bottom Left"
        case .bottomCenter: return "Bottom Center"
        case .bottomRight: return "Bottom Right"
        case .hidden: return "Hidden"
        }
    }
}

public enum HeaderLayout: String, CaseIterable, Sendable {
    case standard = "standard"
    case minimal = "minimal"
    case detailed = "detailed"
    case modern = "modern"
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .minimal: return "Minimal"
        case .detailed: return "Detailed"
        case .modern: return "Modern"
        }
    }
}

public enum FooterLayout: String, CaseIterable, Sendable {
    case standard = "standard"
    case minimal = "minimal"
    case detailed = "detailed"
    case signature = "signature"
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .minimal: return "Minimal"
        case .detailed: return "Detailed"
        case .signature: return "With Signature"
        }
    }
}