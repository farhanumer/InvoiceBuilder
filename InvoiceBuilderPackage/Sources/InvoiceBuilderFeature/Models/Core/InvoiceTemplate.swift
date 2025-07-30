import Foundation
import SwiftUI

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

// MARK: - Built-in Templates

extension InvoiceTemplate {
    public static let builtInTemplates: [InvoiceTemplate] = [
        // Professional Templates
        .classic,
        .modern,
        .executive,
        .corporate,
        
        // Creative Templates
        .creative,
        .colorful,
        .artistic,
        
        // Minimal Templates
        .minimal,
        .clean,
        .simple,
        
        // Service Templates
        .consulting,
        .freelancer,
        .agency,
        
        // Product Templates
        .retail,
        .ecommerce,
        .wholesale
    ]
    
    // Classic Professional Template
    public static let classic = InvoiceTemplate(
        name: "classic",
        displayName: "Classic",
        templateDescription: "A timeless professional invoice template",
        isDefault: true,
        primaryColor: "#2563EB",
        secondaryColor: "#64748B",
        accentColor: "#0F172A",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .standard
    )
    
    // Modern Professional Template
    public static let modern = InvoiceTemplate(
        name: "modern",
        displayName: "Modern",
        templateDescription: "Clean and contemporary design",
        primaryColor: "#059669",
        secondaryColor: "#6B7280",
        accentColor: "#111827",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .minimal
    )
    
    // Executive Template
    public static let executive = InvoiceTemplate(
        name: "executive",
        displayName: "Executive",
        templateDescription: "Sophisticated design for high-end businesses",
        primaryColor: "#1F2937",
        secondaryColor: "#374151",
        accentColor: "#DC2626",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topCenter,
        headerLayout: .detailed,
        footerLayout: .detailed
    )
    
    // Corporate Template
    public static let corporate = InvoiceTemplate(
        name: "corporate",
        displayName: "Corporate",
        templateDescription: "Traditional corporate styling",
        primaryColor: "#1E40AF",
        secondaryColor: "#475569",
        accentColor: "#0F172A",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .detailed,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Creative Template
    public static let creative = InvoiceTemplate(
        name: "creative",
        displayName: "Creative",
        templateDescription: "Vibrant and artistic design",
        primaryColor: "#7C3AED",
        secondaryColor: "#A78BFA",
        accentColor: "#EC4899",
        fontFamily: "System",
        fontSize: 13,
        logoPosition: .topCenter,
        headerLayout: .modern,
        footerLayout: .minimal
    )
    
    // Colorful Template
    public static let colorful = InvoiceTemplate(
        name: "colorful",
        displayName: "Colorful",
        templateDescription: "Bright and energetic design",
        primaryColor: "#EF4444",
        secondaryColor: "#F97316",
        accentColor: "#EAB308",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .modern,
        footerLayout: .standard
    )
    
    // Artistic Template
    public static let artistic = InvoiceTemplate(
        name: "artistic",
        displayName: "Artistic",
        templateDescription: "Unique and expressive design",
        primaryColor: "#06B6D4",
        secondaryColor: "#0891B2",
        accentColor: "#BE185D",
        fontFamily: "System",
        fontSize: 13,
        logoPosition: .topRight,
        headerLayout: .minimal,
        footerLayout: .signature
    )
    
    // Minimal Template
    public static let minimal = InvoiceTemplate(
        name: "minimal",
        displayName: "Minimal",
        templateDescription: "Clean and uncluttered design",
        primaryColor: "#000000",
        secondaryColor: "#6B7280",
        accentColor: "#374151",
        fontFamily: "System",
        fontSize: 11,
        logoPosition: .topLeft,
        headerLayout: .minimal,
        footerLayout: .minimal,
        showTaxColumn: false,
        showDiscountColumn: false
    )
    
    // Clean Template
    public static let clean = InvoiceTemplate(
        name: "clean",
        displayName: "Clean",
        templateDescription: "Simple and organized layout",
        primaryColor: "#374151",
        secondaryColor: "#9CA3AF",
        accentColor: "#111827",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .standard
    )
    
    // Simple Template
    public static let simple = InvoiceTemplate(
        name: "simple",
        displayName: "Simple",
        templateDescription: "Straightforward and efficient",
        primaryColor: "#4B5563",
        secondaryColor: "#6B7280",
        accentColor: "#1F2937",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .standard
    )
    
    // Consulting Template
    public static let consulting = InvoiceTemplate(
        name: "consulting",
        displayName: "Consulting",
        templateDescription: "Professional service-focused design",
        primaryColor: "#0F766E",
        secondaryColor: "#14B8A6",
        accentColor: "#134E4A",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .detailed
    )
    
    // Freelancer Template
    public static let freelancer = InvoiceTemplate(
        name: "freelancer",
        displayName: "Freelancer",
        templateDescription: "Perfect for independent professionals",
        primaryColor: "#7C2D12",
        secondaryColor: "#EA580C",
        accentColor: "#431407",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .signature
    )
    
    // Agency Template
    public static let agency = InvoiceTemplate(
        name: "agency",
        displayName: "Agency",
        templateDescription: "Modern design for creative agencies",
        primaryColor: "#5B21B6",
        secondaryColor: "#8B5CF6",
        accentColor: "#3730A3",
        fontFamily: "System",
        fontSize: 13,
        logoPosition: .topCenter,
        headerLayout: .modern,
        footerLayout: .minimal
    )
    
    // Retail Template
    public static let retail = InvoiceTemplate(
        name: "retail",
        displayName: "Retail",
        templateDescription: "Designed for retail businesses",
        primaryColor: "#DC2626",
        secondaryColor: "#F87171",
        accentColor: "#991B1B",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .standard,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // E-commerce Template
    public static let ecommerce = InvoiceTemplate(
        name: "ecommerce",
        displayName: "E-commerce",
        templateDescription: "Modern online store styling",
        primaryColor: "#059669",
        secondaryColor: "#10B981",
        accentColor: "#065F46",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .detailed,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Wholesale Template
    public static let wholesale = InvoiceTemplate(
        name: "wholesale",
        displayName: "Wholesale",
        templateDescription: "B2B focused design",
        primaryColor: "#1F2937",
        secondaryColor: "#4B5563",
        accentColor: "#111827",
        fontFamily: "System",
        fontSize: 11,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .detailed,
        showTaxColumn: true,
        showDiscountColumn: true
    )
}

// MARK: - Template Categories

public enum TemplateCategory: String, CaseIterable, Sendable {
    case all = "all"
    case professional = "professional"
    case creative = "creative"
    case minimal = "minimal"
    case service = "service"
    case product = "product"
    
    public var displayName: String {
        switch self {
        case .all: return "All Templates"
        case .professional: return "Professional"
        case .creative: return "Creative"
        case .minimal: return "Minimal"
        case .service: return "Service"
        case .product: return "Product"
        }
    }
    
    public func templates() -> [InvoiceTemplate] {
        switch self {
        case .all:
            return InvoiceTemplate.builtInTemplates
        case .professional:
            return [.classic, .modern, .executive, .corporate]
        case .creative:
            return [.creative, .colorful, .artistic]
        case .minimal:
            return [.minimal, .clean, .simple]
        case .service:
            return [.consulting, .freelancer, .agency]
        case .product:
            return [.retail, .ecommerce, .wholesale]
        }
    }
}

// MARK: - Color Utilities

extension InvoiceTemplate {
    public func primaryColorSwiftUI() -> Color {
        return Color(hex: primaryColor) ?? .blue
    }
    
    public func secondaryColorSwiftUI() -> Color {
        return Color(hex: secondaryColor) ?? .gray
    }
    
    public func accentColorSwiftUI() -> Color {
        return Color(hex: accentColor) ?? .black
    }
}

