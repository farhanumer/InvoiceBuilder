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
        NavigationStack {
            #if os(macOS)
            // macOS: Side-by-side layout similar to iOS but optimized for desktop
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Customization Panel
                    VStack(spacing: 0) {
                        headerSection
                        Divider()
                        tabSelector
                        
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
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    }
                    .frame(width: showPreview ? geometry.size.width * 0.4 : geometry.size.width)
                    
                    if showPreview {
                        Divider()
                        
                        // Preview Panel
                        VStack(spacing: 0) {
                            HStack {
                                Text("Preview")
                                    .font(.headline)
                                    .fontWeight(.semibold)
                                
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
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color.gray.opacity(0.1))
                        }
                        .frame(width: geometry.size.width * 0.6)
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(isSaving)
                }
                
                if !showPreview {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Show Preview") {
                            withAnimation {
                                showPreview = true
                            }
                        }
                    }
                }
            }
            #else
            // iOS: Side-by-side layout
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    // Customization Panel
                    VStack(spacing: 0) {
                        headerSection
                        Divider()
                        tabSelector
                        
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
                        actionButtons
                    }
                    .frame(width: showPreview ? geometry.size.width * 0.4 : geometry.size.width)
                    
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
            #endif
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
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Modify colors, fonts, and layout options")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
    }
    
    // MARK: - Tab Selector
    
    private var tabSelector: some View {
        HStack(spacing: 0) {
            ForEach(CustomizationTab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: tab.icon)
                            .font(.system(size: 16))
                        
                        Text(tab.displayName)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .background(selectedTab == tab ? Color.blue.opacity(0.1) : Color.clear)
                .overlay(
                    Rectangle()
                        .frame(height: 2)
                        .foregroundColor(selectedTab == tab ? .blue : .clear),
                    alignment: .bottom
                )
            }
        }
        .background(Color.gray.opacity(0.05))
    }
    
    // MARK: - Customization Sections
    
    private var colorCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Colors")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                ColorPickerRow(
                    title: "Primary Color",
                    subtitle: "Main brand color for headers and accents",
                    color: Color(hex: template.primaryColor) ?? .blue
                ) { newColor in
                    template.primaryColor = newColor.toHex()
                }
                
                ColorPickerRow(
                    title: "Secondary Color",
                    subtitle: "Supporting color for text and details",
                    color: Color(hex: template.secondaryColor) ?? .gray
                ) { newColor in
                    template.secondaryColor = newColor.toHex()
                }
                
                ColorPickerRow(
                    title: "Accent Color",
                    subtitle: "Highlight color for important elements",
                    color: Color(hex: template.accentColor) ?? .orange
                ) { newColor in
                    template.accentColor = newColor.toHex()
                }
            }
        }
    }
    
    private var fontCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Typography")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Font customization coming soon")
                .foregroundStyle(.secondary)
        }
    }
    
    private var layoutCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Layout Options")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Layout customization coming soon")
                .foregroundStyle(.secondary)
        }
    }
    
    private var elementCustomization: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Invoice Elements")
                .font(.headline)
                .fontWeight(.semibold)
            
            Text("Element customization coming soon")
                .foregroundStyle(.secondary)
        }
    }
    
    // MARK: - Action Buttons (iOS only)
    
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
                saveTemplate()
            } label: {
                if isSaving {
                    ProgressView()
                        .scaleEffect(0.8)
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Save")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isSaving)
        }
        .padding()
    }
    
    // MARK: - Methods
    
    private func saveTemplate() {
        isSaving = true
        onSave(template)
        dismiss()
    }
}

// MARK: - Supporting Types

private enum CustomizationTab: CaseIterable {
    case colors
    case fonts
    case layout
    case elements
    
    var displayName: String {
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


#Preview {
    TemplateCustomizationView(template: .classic) { _ in
        // Handle save
    }
    .environment(InvoiceTemplateService.shared)
}