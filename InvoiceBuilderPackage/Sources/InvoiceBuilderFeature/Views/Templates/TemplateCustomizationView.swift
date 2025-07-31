import SwiftUI

@MainActor
struct TemplateCustomizationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(InvoiceTemplateService.self) private var templateService
    
    @State private var template: InvoiceTemplate
    @State private var originalTemplate: InvoiceTemplate
    @State private var selectedTab: CustomizationTab = .colors
    @State private var showPreview = true
    @State private var isSaving = false
    @State private var showError = false
    @State private var errorMessage = ""
    
    let onSave: (InvoiceTemplate) -> Void
    
    init(template: InvoiceTemplate, onSave: @escaping (InvoiceTemplate) -> Void) {
        self._template = State(initialValue: template)
        self._originalTemplate = State(initialValue: template)
        self.onSave = onSave
    }
    
    var body: some View {
        GeometryReader { geometry in
            HStack(spacing: 0) {
                // Customization Panel
                VStack(spacing: 0) {
                    // Header
                    headerSection
                    
                    Divider()
                    
                    // Tabs
                    tabSelector
                    
                    // Content
                    ScrollView {
                        VStack(spacing: 20) {
                            switch selectedTab {
                            case .colors:
                                colorCustomization
                            case .fonts:
                                fontCustomization
                            case .layout:
                                layoutCustomization
                            case .elements:
                                elementCustomization
                            }
                        }
                        .padding()
                    }
                    
                    Divider()
                    
                    // Actions
                    actionButtons
                }
                .frame(width: showPreview ? geometry.size.width * 0.4 : geometry.size.width)
                .background(Color.clear)
                
                if showPreview {
                    Divider()
                    
                    // Preview
                    VStack(spacing: 0) {
                        HStack {
                            Text("Preview")
                                .font(.headline)
                            
                            Spacer()
                            
                            Button {
                                withAnimation {
                                    showPreview = false
                                }
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        .padding()
                        
                        Divider()
                        
                        ScrollView {
                            templateService.generateTemplatePreview(template)
                                .padding()
                                .background(Color.white)
                                .cornerRadius(8)
                                .shadow(radius: 2)
                                .padding()
                        }
                        .background(Color.gray.opacity(0.1))
                    }
                    .frame(width: geometry.size.width * 0.6)
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") {
                showError = false
            }
        } message: {
            Text(errorMessage)
        }
    }
    
    // MARK: - Header Section
    
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Customize Template")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Modify colors, fonts, and layout settings")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding()
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CustomizationTab.allCases, id: \.self) { tab in
                Button {
                    withAnimation {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.title3)
                        
                        Text(tab.title)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(selectedTab == tab ? Color.accentColor.opacity(0.1) : Color.clear)
                    .foregroundStyle(selectedTab == tab ? Color.accentColor : .secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .background(Color.gray.opacity(0.1))
    }
    
    // MARK: - Color Customization
    
    private var colorCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Colors")
                .font(.headline)
            
            ColorPickerRow(
                title: "Primary Color",
                subtitle: "Main text and headers",
                color: Color(hex: template.primaryColor) ?? .black
            ) { color in
                template.primaryColor = color.toHex()
            }
            
            ColorPickerRow(
                title: "Secondary Color",
                subtitle: "Subtitles and metadata",
                color: Color(hex: template.secondaryColor) ?? .gray
            ) { color in
                template.secondaryColor = color.toHex()
            }
            
            ColorPickerRow(
                title: "Accent Color",
                subtitle: "Important elements and highlights",
                color: Color(hex: template.accentColor) ?? .blue
            ) { color in
                template.accentColor = color.toHex()
            }
            
            // Preset color schemes
            VStack(alignment: .leading, spacing: 8) {
                Text("Preset Color Schemes")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(ColorScheme.presets, id: \.name) { scheme in
                        Button {
                            template.primaryColor = scheme.primary
                            template.secondaryColor = scheme.secondary
                            template.accentColor = scheme.accent
                        } label: {
                            VStack(spacing: 4) {
                                HStack(spacing: 2) {
                                    Circle()
                                        .fill(Color(hex: scheme.primary) ?? .black)
                                        .frame(width: 16, height: 16)
                                    Circle()
                                        .fill(Color(hex: scheme.secondary) ?? .gray)
                                        .frame(width: 16, height: 16)
                                    Circle()
                                        .fill(Color(hex: scheme.accent) ?? .blue)
                                        .frame(width: 16, height: 16)
                                }
                                
                                Text(scheme.name)
                                    .font(.caption2)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(6)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Font Customization
    
    private var fontCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Typography")
                .font(.headline)
            
            // Font Family
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Family")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Font Family", selection: $template.fontFamily) {
                    ForEach(FontFamily.allCases, id: \.rawValue) { family in
                        Text(family.displayName)
                            .tag(family.rawValue)
                    }
                }
                .pickerStyle(.segmented)
            }
            
            // Font Size
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Base Font Size")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text("\(template.fontSize) pt")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Slider(value: Binding(
                    get: { Double(template.fontSize) },
                    set: { template.fontSize = Int($0) }
                ), in: 10...16, step: 1)
                
                Text("Affects overall text size in the invoice")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            // Font Preview
            VStack(alignment: .leading, spacing: 8) {
                Text("Font Preview")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice Header")
                        .font(Font.custom(template.fontFamily, size: CGFloat(template.fontSize + 6)))
                        .fontWeight(.bold)
                    
                    Text("Client Name and Details")
                        .font(Font.custom(template.fontFamily, size: CGFloat(template.fontSize)))
                    
                    Text("Item descriptions and invoice content")
                        .font(Font.custom(template.fontFamily, size: CGFloat(template.fontSize - 2)))
                        .foregroundStyle(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
            }
        }
    }
    
    // MARK: - Layout Customization
    
    private var layoutCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Layout Options")
                .font(.headline)
            
            // Logo Position
            VStack(alignment: .leading, spacing: 8) {
                Text("Logo Position")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Picker("Logo Position", selection: $template.logoPosition) {
                    ForEach(LogoPosition.allCases, id: \.self) { position in
                        Text(position.displayName)
                            .tag(position)
                    }
                }
                .pickerStyle(.menu)
            }
            
            // Header Layout
            VStack(alignment: .leading, spacing: 8) {
                Text("Header Style")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(HeaderLayout.allCases, id: \.self) { layout in
                        Button {
                            template.headerLayout = layout
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: layout.icon)
                                    .font(.title3)
                                
                                Text(layout.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(template.headerLayout == layout ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundStyle(template.headerLayout == layout ? Color.accentColor : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            
            // Footer Layout
            VStack(alignment: .leading, spacing: 8) {
                Text("Footer Style")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                    ForEach(FooterLayout.allCases, id: \.self) { layout in
                        Button {
                            template.footerLayout = layout
                        } label: {
                            VStack(spacing: 4) {
                                Image(systemName: layout.icon)
                                    .font(.title3)
                                
                                Text(layout.displayName)
                                    .font(.caption)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(template.footerLayout == layout ? Color.accentColor.opacity(0.1) : Color.gray.opacity(0.1))
                            .foregroundStyle(template.footerLayout == layout ? Color.accentColor : .primary)
                            .cornerRadius(8)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
    
    // MARK: - Element Customization
    
    private var elementCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invoice Elements")
                .font(.headline)
            
            Toggle("Show Tax Column", isOn: $template.showTaxColumn)
            
            Toggle("Show Discount Column", isOn: $template.showDiscountColumn)
            
            Toggle("Show Notes Section", isOn: $template.showNotesSection)
            
            Toggle("Show Terms Section", isOn: $template.showTermsSection)
            
            Text("Additional columns and sections can be toggled based on your business needs")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
    }
    
    // MARK: - Action Buttons
    
    private var actionButtons: some View {
        HStack(spacing: 12) {
            if !showPreview {
                Button {
                    withAnimation {
                        showPreview = true
                    }
                } label: {
                    Label("Show Preview", systemImage: "eye")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            
            Button {
                template = originalTemplate
            } label: {
                Text("Reset")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            
            Button {
                Task {
                    await saveTemplate()
                }
            } label: {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Save Changes")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
        .padding()
    }
    
    // MARK: - Save
    
    private func saveTemplate() async {
        isSaving = true
        
        do {
            if template.isCustom {
                try await templateService.updateCustomTemplate(template)
            }
            
            onSave(template)
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
            showError = true
        }
        
        isSaving = false
    }
}

// MARK: - Supporting Types

private enum CustomizationTab: String, CaseIterable {
    case colors
    case fonts
    case layout
    case elements
    
    var title: String {
        switch self {
        case .colors: return "Colors"
        case .fonts: return "Fonts"
        case .layout: return "Layout"
        case .elements: return "Elements"
        }
    }
    
    var icon: String {
        switch self {
        case .colors: return "paintpalette"
        case .fonts: return "textformat"
        case .layout: return "rectangle.split.3x1"
        case .elements: return "checklist"
        }
    }
}

private struct ColorPickerRow: View {
    let title: String
    let subtitle: String
    @State var color: Color
    let onChange: (Color) -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            ColorPicker("", selection: $color)
                .labelsHidden()
                .onChange(of: color) { _, newValue in
                    onChange(newValue)
                }
        }
    }
}

private struct ColorScheme {
    let name: String
    let primary: String
    let secondary: String
    let accent: String
    
    static let presets: [ColorScheme] = [
        ColorScheme(name: "Professional", primary: "#2563EB", secondary: "#64748B", accent: "#0F172A"),
        ColorScheme(name: "Modern", primary: "#059669", secondary: "#6B7280", accent: "#111827"),
        ColorScheme(name: "Executive", primary: "#1F2937", secondary: "#374151", accent: "#DC2626"),
        ColorScheme(name: "Creative", primary: "#7C3AED", secondary: "#A78BFA", accent: "#EC4899"),
        ColorScheme(name: "Minimal", primary: "#000000", secondary: "#6B7280", accent: "#374151"),
        ColorScheme(name: "Ocean", primary: "#06B6D4", secondary: "#0891B2", accent: "#0E7490"),
        ColorScheme(name: "Forest", primary: "#059669", secondary: "#10B981", accent: "#065F46"),
        ColorScheme(name: "Sunset", primary: "#DC2626", secondary: "#EF4444", accent: "#F97316"),
        ColorScheme(name: "Royal", primary: "#4F46E5", secondary: "#6366F1", accent: "#4338CA"),
        ColorScheme(name: "Earth", primary: "#92400E", secondary: "#B45309", accent: "#78350F")
    ]
}

private enum FontFamily: String, CaseIterable {
    case system = "System"
    case helvetica = "Helvetica"
    case times = "Times New Roman"
    case georgia = "Georgia"
    case avenir = "Avenir"
    
    var displayName: String {
        switch self {
        case .system: return "System Default"
        case .helvetica: return "Helvetica"
        case .times: return "Times"
        case .georgia: return "Georgia"
        case .avenir: return "Avenir"
        }
    }
}

// MARK: - Layout Icons

private extension HeaderLayout {
    var icon: String {
        switch self {
        case .standard: return "rectangle.grid.1x2"
        case .minimal: return "minus.rectangle"
        case .detailed: return "rectangle.grid.2x2"
        case .modern: return "rectangle.badge.plus"
        }
    }
}

private extension FooterLayout {
    var icon: String {
        switch self {
        case .standard: return "rectangle.bottomthird.inset.filled"
        case .minimal: return "minus.rectangle"
        case .detailed: return "text.alignleft"
        case .signature: return "signature"
        }
    }
}

// MARK: - Preview

#Preview {
    TemplateCustomizationView(template: .classic) { _ in
        // Handle save
    }
    .environment(InvoiceTemplateService.shared)
}