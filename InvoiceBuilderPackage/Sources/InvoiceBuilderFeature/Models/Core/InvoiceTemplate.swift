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
    public var backgroundColor: String
    public var backgroundType: BackgroundType
    public var borderStyle: BorderStyle
    public var borderColor: String
    public var fontFamily: String
    public var fontSize: Int
    public var logoPosition: LogoPosition
    public var headerLayout: HeaderLayout
    public var footerLayout: FooterLayout
    public var contentLayout: ContentLayout
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
        backgroundColor: String = "#FFFFFF",
        backgroundType: BackgroundType = .solid,
        borderStyle: BorderStyle = .none,
        borderColor: String = "#CCCCCC",
        fontFamily: String = "System",
        fontSize: Int = 12,
        logoPosition: LogoPosition = .topLeft,
        headerLayout: HeaderLayout = .standard,
        footerLayout: FooterLayout = .standard,
        contentLayout: ContentLayout = .standard,
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
        self.backgroundColor = backgroundColor
        self.backgroundType = backgroundType
        self.borderStyle = borderStyle
        self.borderColor = borderColor
        self.fontFamily = fontFamily
        self.fontSize = fontSize
        self.logoPosition = logoPosition
        self.headerLayout = headerLayout
        self.footerLayout = footerLayout
        self.contentLayout = contentLayout
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
        self.backgroundColor = entity.backgroundColor
        self.backgroundType = BackgroundType(rawValue: entity.backgroundType) ?? .solid
        self.borderStyle = BorderStyle(rawValue: entity.borderStyle) ?? .none
        self.borderColor = entity.borderColor
        self.fontFamily = entity.fontFamily
        self.fontSize = entity.fontSize
        self.logoPosition = LogoPosition(rawValue: entity.logoPosition) ?? .topLeft
        self.headerLayout = HeaderLayout(rawValue: entity.headerLayout) ?? .standard
        self.footerLayout = FooterLayout(rawValue: entity.footerLayout) ?? .standard
        self.contentLayout = ContentLayout(rawValue: entity.contentLayout) ?? .standard
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

public enum BackgroundType: String, CaseIterable, Sendable {
    case solid = "solid"
    case gradient = "gradient"
    case pattern = "pattern"
    case texture = "texture"
    case image = "image"
    
    public var displayName: String {
        switch self {
        case .solid: return "Solid Color"
        case .gradient: return "Gradient"
        case .pattern: return "Pattern"
        case .texture: return "Texture"
        case .image: return "Image"
        }
    }
}

public enum BorderStyle: String, CaseIterable, Sendable {
    case none = "none"
    case solid = "solid"
    case dashed = "dashed"
    case dotted = "dotted"
    case double = "double"
    case thick = "thick"
    case shadow = "shadow"
    
    public var displayName: String {
        switch self {
        case .none: return "No Border"
        case .solid: return "Solid"
        case .dashed: return "Dashed"
        case .dotted: return "Dotted"
        case .double: return "Double"
        case .thick: return "Thick"
        case .shadow: return "Shadow"
        }
    }
}

public enum ContentLayout: String, CaseIterable, Sendable {
    case standard = "standard"
    case compact = "compact"
    case spacious = "spacious"
    case sidebar = "sidebar"
    case grid = "grid"
    case modern = "modern"
    
    public var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .compact: return "Compact"
        case .spacious: return "Spacious"
        case .sidebar: return "Sidebar"
        case .grid: return "Grid"
        case .modern: return "Modern"
        }
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
        .professional,
        
        // Creative Templates
        .creative,
        .colorful,
        .artistic,
        .watercolor,
        .geometric,
        
        // Minimal Templates
        .minimal,
        .clean,
        .simple,
        .pure,
        .neat,
        
        // Service Templates
        .consulting,
        .freelancer,
        .agency,
        
        // Product Templates
        .retail,
        .ecommerce,
        .wholesale,
        
        // Themed Templates
        .techBlue,
        .forestGreen,
        .crimson,
        .midnight,
        .sunrise,
        
        // Enhanced Layout Templates
        .gradient,
        .bordered,
        .shadowed,
        .marble,
        .geometricPattern,
        .watermark,
        .sidebar,
        .compact,
        .spacious,
        .modern2024
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
    
    // MARK: - Additional Professional Templates
    
    // Professional Template
    public static let professional = InvoiceTemplate(
        name: "professional",
        displayName: "Professional",
        templateDescription: "Polished business template with elegant typography",
        primaryColor: "#374151",
        secondaryColor: "#6B7280",
        accentColor: "#1F2937",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .detailed,
        footerLayout: .signature,
        showTaxColumn: true,
        showDiscountColumn: false
    )
    
    // MARK: - Additional Creative Templates
    
    // Watercolor Template
    public static let watercolor = InvoiceTemplate(
        name: "watercolor",
        displayName: "Watercolor",
        templateDescription: "Soft artistic design with gentle colors",
        primaryColor: "#7C3AED",
        secondaryColor: "#A78BFA",
        accentColor: "#5B21B6",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .detailed,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Geometric Template
    public static let geometric = InvoiceTemplate(
        name: "geometric",
        displayName: "Geometric",
        templateDescription: "Modern design with geometric elements",
        primaryColor: "#F59E0B",
        secondaryColor: "#FCD34D",
        accentColor: "#D97706",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topCenter,
        headerLayout: .modern,
        footerLayout: .standard,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // MARK: - Additional Minimal Templates
    
    // Pure Template
    public static let pure = InvoiceTemplate(
        name: "pure",
        displayName: "Pure",
        templateDescription: "Ultra-minimalist white design",
        primaryColor: "#000000",
        secondaryColor: "#9CA3AF",
        accentColor: "#374151",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .minimal,
        footerLayout: .minimal,
        showTaxColumn: false,
        showDiscountColumn: false
    )
    
    // Neat Template
    public static let neat = InvoiceTemplate(
        name: "neat",
        displayName: "Neat",
        templateDescription: "Clean and organized layout",
        primaryColor: "#1F2937",
        secondaryColor: "#6B7280",
        accentColor: "#111827",
        fontFamily: "System",
        fontSize: 11,
        logoPosition: .topRight,
        headerLayout: .standard,
        footerLayout: .minimal,
        showTaxColumn: true,
        showDiscountColumn: false
    )
    
    // MARK: - Themed Color Templates
    
    // Tech Blue Template
    public static let techBlue = InvoiceTemplate(
        name: "tech_blue",
        displayName: "Tech Blue",
        templateDescription: "Technology-focused blue theme",
        primaryColor: "#1E40AF",
        secondaryColor: "#3B82F6",
        accentColor: "#1E3A8A",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .modern,
        footerLayout: .detailed,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Forest Green Template
    public static let forestGreen = InvoiceTemplate(
        name: "forest_green",
        displayName: "Forest Green",
        templateDescription: "Nature-inspired green design",
        primaryColor: "#059669",
        secondaryColor: "#10B981",
        accentColor: "#047857",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .standard,
        footerLayout: .standard,
        showTaxColumn: true,
        showDiscountColumn: false
    )
    
    // Crimson Template
    public static let crimson = InvoiceTemplate(
        name: "crimson",
        displayName: "Crimson",
        templateDescription: "Bold red accent design",
        primaryColor: "#DC2626",
        secondaryColor: "#EF4444",
        accentColor: "#B91C1C",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topCenter,
        headerLayout: .detailed,
        footerLayout: .detailed,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Midnight Template
    public static let midnight = InvoiceTemplate(
        name: "midnight",
        displayName: "Midnight",
        templateDescription: "Sophisticated dark theme",
        primaryColor: "#111827",
        secondaryColor: "#374151",
        accentColor: "#4B5563",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .standard,
        footerLayout: .signature,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Sunrise Template
    public static let sunrise = InvoiceTemplate(
        name: "sunrise",
        displayName: "Sunrise",
        templateDescription: "Warm orange and gold theme",
        primaryColor: "#EA580C",
        secondaryColor: "#FB923C",
        accentColor: "#C2410C",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .standard,
        showTaxColumn: true,
        showDiscountColumn: false
    )
    
    // MARK: - Enhanced Layout Templates
    
    // Gradient Background Template
    public static let gradient = InvoiceTemplate(
        name: "gradient",
        displayName: "Ocean Gradient",
        templateDescription: "Modern gradient background with flowing colors",
        primaryColor: "#0EA5E9",
        secondaryColor: "#0284C7",
        accentColor: "#FFFFFF",
        backgroundColor: "#0EA5E9",
        backgroundType: .gradient,
        borderStyle: .none,
        borderColor: "#FFFFFF",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .minimal,
        contentLayout: .modern,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Bordered Professional Template
    public static let bordered = InvoiceTemplate(
        name: "bordered",
        displayName: "Executive Border",
        templateDescription: "Elegant bordered design with double-line frames",
        primaryColor: "#1F2937",
        secondaryColor: "#6B7280",
        accentColor: "#3B82F6",
        backgroundColor: "#F9FAFB",
        backgroundType: .solid,
        borderStyle: .double,
        borderColor: "#1F2937",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .detailed,
        footerLayout: .signature,
        contentLayout: .spacious,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Shadow Effect Template
    public static let shadowed = InvoiceTemplate(
        name: "shadowed",
        displayName: "Shadow Card",
        templateDescription: "Modern card design with elegant shadow effects",
        primaryColor: "#374151",
        secondaryColor: "#9CA3AF",
        accentColor: "#10B981",
        backgroundColor: "#FFFFFF",
        backgroundType: .solid,
        borderStyle: .shadow,
        borderColor: "#E5E7EB",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topCenter,
        headerLayout: .modern,
        footerLayout: .minimal,
        contentLayout: .modern,
        showTaxColumn: true,
        showDiscountColumn: false
    )
    
    // Marble Texture Template
    public static let marble = InvoiceTemplate(
        name: "marble",
        displayName: "Marble Luxury",
        templateDescription: "Sophisticated marble background with gold accents",
        primaryColor: "#B45309",
        secondaryColor: "#92400E",
        accentColor: "#FBBF24",
        backgroundColor: "#F3F4F6",
        backgroundType: .texture,
        borderStyle: .solid,
        borderColor: "#B45309",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .detailed,
        footerLayout: .detailed,
        contentLayout: .spacious,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Geometric Pattern Template
    public static let geometricPattern = InvoiceTemplate(
        name: "geometric_pattern",
        displayName: "Geometric Pattern",
        templateDescription: "Contemporary geometric patterns with clean lines",
        primaryColor: "#7C3AED",
        secondaryColor: "#A78BFA",
        accentColor: "#FFFFFF",
        backgroundColor: "#EDE9FE",
        backgroundType: .pattern,
        borderStyle: .solid,
        borderColor: "#7C3AED",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topRight,
        headerLayout: .modern,
        footerLayout: .standard,
        contentLayout: .grid,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Watermark Template
    public static let watermark = InvoiceTemplate(
        name: "watermark",
        displayName: "Branded Watermark",
        templateDescription: "Subtle watermark background with professional layout",
        primaryColor: "#111827",
        secondaryColor: "#6B7280",
        accentColor: "#3B82F6",
        backgroundColor: "#FFFFFF",
        backgroundType: .image,
        borderStyle: .none,
        borderColor: "#E5E7EB",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .detailed,
        footerLayout: .signature,
        contentLayout: .standard,
        showTaxColumn: true,
        showDiscountColumn: false
    )
    
    // Sidebar Layout Template
    public static let sidebar = InvoiceTemplate(
        name: "sidebar",
        displayName: "Modern Sidebar",
        templateDescription: "Two-column layout with colored sidebar accent",
        primaryColor: "#0F172A",
        secondaryColor: "#475569",
        accentColor: "#06B6D4",
        backgroundColor: "#FFFFFF",
        backgroundType: .solid,
        borderStyle: .none,
        borderColor: "#E2E8F0",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .modern,
        footerLayout: .minimal,
        contentLayout: .sidebar,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Compact Layout Template
    public static let compact = InvoiceTemplate(
        name: "compact",
        displayName: "Compact Pro",
        templateDescription: "Space-efficient design for detailed invoices",
        primaryColor: "#DC2626",
        secondaryColor: "#991B1B",
        accentColor: "#FEE2E2",
        backgroundColor: "#FFFFFF",
        backgroundType: .solid,
        borderStyle: .dashed,
        borderColor: "#DC2626",
        fontFamily: "System",
        fontSize: 11,
        logoPosition: .topRight,
        headerLayout: .minimal,
        footerLayout: .minimal,
        contentLayout: .compact,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Spacious Layout Template
    public static let spacious = InvoiceTemplate(
        name: "spacious",
        displayName: "Spacious Elite",
        templateDescription: "Premium spacious layout with generous white space",
        primaryColor: "#1E40AF",
        secondaryColor: "#3B82F6",
        accentColor: "#EFF6FF",
        backgroundColor: "#FAFAFA",
        backgroundType: .solid,
        borderStyle: .thick,
        borderColor: "#1E40AF",
        fontFamily: "System",
        fontSize: 13,
        logoPosition: .topCenter,
        headerLayout: .detailed,
        footerLayout: .detailed,
        contentLayout: .spacious,
        showTaxColumn: true,
        showDiscountColumn: true
    )
    
    // Modern 2024 Template
    public static let modern2024 = InvoiceTemplate(
        name: "modern2024",
        displayName: "Modern 2024",
        templateDescription: "Latest design trends with contemporary styling",
        primaryColor: "#18181B",
        secondaryColor: "#71717A",
        accentColor: "#F59E0B",
        backgroundColor: "#FFFFFF",
        backgroundType: .gradient,
        borderStyle: .shadow,
        borderColor: "#F3F4F6",
        fontFamily: "System",
        fontSize: 12,
        logoPosition: .topLeft,
        headerLayout: .modern,
        footerLayout: .signature,
        contentLayout: .modern,
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
    case themed = "themed"
    case enhanced = "enhanced"
    
    public var displayName: String {
        switch self {
        case .all: return "All Templates"
        case .professional: return "Professional"
        case .creative: return "Creative"
        case .minimal: return "Minimal"
        case .service: return "Service"
        case .product: return "Product"
        case .themed: return "Color Themes"
        case .enhanced: return "Enhanced Layouts"
        }
    }
    
    public func templates() -> [InvoiceTemplate] {
        switch self {
        case .all:
            return InvoiceTemplate.builtInTemplates
        case .professional:
            return [.classic, .modern, .executive, .corporate, .professional, .bordered, .shadowed]
        case .creative:
            return [.creative, .colorful, .artistic, .watercolor, .geometric, .gradient, .marble]
        case .minimal:
            return [.minimal, .clean, .simple, .pure, .neat, .compact]
        case .service:
            return [.consulting, .freelancer, .agency, .professional, .sidebar]
        case .product:
            return [.retail, .ecommerce, .wholesale, .spacious]
        case .themed:
            return [.techBlue, .forestGreen, .crimson, .midnight, .sunrise]
        case .enhanced:
            return [.gradient, .bordered, .shadowed, .marble, .geometricPattern, .watermark, .sidebar, .compact, .spacious, .modern2024]
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

