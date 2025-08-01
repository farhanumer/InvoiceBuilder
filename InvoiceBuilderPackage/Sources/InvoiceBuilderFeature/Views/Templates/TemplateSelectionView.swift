import SwiftUI
import SwiftData

@MainActor
public struct TemplateSelectionView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var savedTemplates: [InvoiceTemplateEntity]
    // @State private var templateService = InvoiceTemplateService.shared // Temporarily disabled
    @State private var searchText = ""
    @State private var selectedCategory: TemplateFilterCategory = .all
    @State private var selectedTemplate: InvoiceTemplate?
    @State private var showingTemplatePreview = false
    @State private var showingCreateTemplate = false
    
    let onTemplateSelected: (InvoiceTemplate) -> Void
    
    private var filteredTemplates: [InvoiceTemplate] {
        let allTemplates = InvoiceTemplate.builtInTemplates + savedTemplates.map { InvoiceTemplate(from: $0) }
        
        var filtered = allTemplates.filter { template in
            if selectedCategory != .all {
                switch selectedCategory {
                case .professional:
                    return TemplateCategory.professional.templates().contains { $0.id == template.id }
                case .creative:
                    return TemplateCategory.creative.templates().contains { $0.id == template.id }
                case .minimal:
                    return TemplateCategory.minimal.templates().contains { $0.id == template.id }
                case .service:
                    return TemplateCategory.service.templates().contains { $0.id == template.id }
                case .product:
                    return TemplateCategory.product.templates().contains { $0.id == template.id }
                case .themed:
                    return TemplateCategory.themed.templates().contains { $0.id == template.id }
                case .enhanced:
                    return TemplateCategory.enhanced.templates().contains { $0.id == template.id }
                case .custom:
                    return template.isCustom
                case .all:
                    break
                }
            }
            return true
        }
        
        if !searchText.isEmpty {
            filtered = filtered.filter { template in
                template.displayName.localizedCaseInsensitiveContains(searchText) ||
                (template.templateDescription?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered.sorted { template1, template2 in
            if template1.isDefault != template2.isDefault {
                return template1.isDefault && !template2.isDefault
            }
            return template1.displayName < template2.displayName
        }
    }
    
    
    public init(onTemplateSelected: @escaping (InvoiceTemplate) -> Void) {
        self.onTemplateSelected = onTemplateSelected
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Section
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    CategorySegmentedControl(selectedCategory: $selectedCategory)
                }
                .padding()
                .background(.regularMaterial)
                
                // Templates Grid
                ScrollView {
                    if filteredTemplates.isEmpty {
                        emptyStateView
                    } else {
                        LazyVGrid(columns: gridColumns, spacing: 16) {
                            ForEach(filteredTemplates) { template in
                                TemplateCard(
                                    template: template,
                                    isSelected: selectedTemplate?.id == template.id
                                ) {
                                    selectedTemplate = template
                                    showingTemplatePreview = true
                                }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Choose Template")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button("Create") {
                        showingCreateTemplate = true
                    }
                }
            }
            .onAppear {
                // templateService.configure(modelContext: modelContext) // Temporarily disabled
            }
            .sheet(isPresented: $showingTemplatePreview) {
                if let template = selectedTemplate {
                    TemplatePreviewView(
                        template: template,
                        onSelect: { selectedTemplate in
                            onTemplateSelected(selectedTemplate)
                            dismiss()
                        },
                        onDuplicate: { template in
                            // Template duplication temporarily disabled
                            print("Template duplication not available")
                        }
                    )
                    #if os(macOS)
                    .frame(minWidth: 800, minHeight: 600)
                    #endif
                }
            }
            .sheet(isPresented: $showingCreateTemplate) {
                Text("Template Creation Coming Soon")
                    .navigationTitle("Create Template")
                    #if os(iOS)
                    .navigationBarTitleDisplayMode(.inline)
                    #endif
                    .toolbar {
                        ToolbarItem(placement: {
                            #if os(iOS)
                            .topBarLeading
                            #else
                            .cancellationAction
                            #endif
                        }()) {
                            Button("Cancel") { showingCreateTemplate = false }
                        }
                    }
            }
        }
    }
    
    private var gridColumns: [GridItem] {
        #if os(iOS)
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        #else
        return [
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16),
            GridItem(.flexible(), spacing: 16)
        ]
        #endif
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "doc.text.magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Templates Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Try adjusting your search or filter criteria")
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Supporting Views

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search templates", text: $text)
                .textFieldStyle(.plain)
            
            if !text.isEmpty {
                Button("Clear") {
                    text = ""
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
    }
}

private struct CategorySegmentedControl: View {
    @Binding var selectedCategory: TemplateFilterCategory
    
    var body: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(TemplateFilterCategory.allCases, id: \.self) { category in
                Text(category.displayName)
                    .tag(category)
            }
        }
        .pickerStyle(.segmented)
    }
}

private struct TemplateCard: View {
    let template: InvoiceTemplate
    let isSelected: Bool
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Preview Image or Placeholder
                templatePreview
                
                // Template Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(template.displayName)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        if template.isDefault {
                            Badge(text: "Default", color: .blue)
                        } else if template.isCustom {
                            Badge(text: "Custom", color: .purple)
                        }
                    }
                    
                    if let description = template.templateDescription {
                        Text(description)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    // Template Features
                    HStack(spacing: 8) {
                        if template.showTaxColumn {
                            FeatureIcon(systemName: "percent", color: .green)
                        }
                        if template.showDiscountColumn {
                            FeatureIcon(systemName: "minus.circle", color: .orange)
                        }
                        if template.showNotesSection {
                            FeatureIcon(systemName: "note.text", color: .blue)
                        }
                        
                        Spacer()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.bottom, 12)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 2)
        )
        .scaleEffect(isSelected ? 0.98 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isSelected)
    }
    
    @ViewBuilder
    private var templatePreview: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(LinearGradient(
                colors: [
                    Color(hex: template.accentColor) ?? .blue,
                    Color(hex: template.primaryColor) ?? .primary
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .frame(height: 120)
            .overlay {
                VStack(spacing: 4) {
                    // Mock header
                    HStack {
                        Circle()
                            .fill(.white.opacity(0.3))
                            .frame(width: 8, height: 8)
                        
                        Rectangle()
                            .fill(.white.opacity(0.4))
                            .frame(width: 30, height: 2)
                        
                        Spacer()
                        
                        Rectangle()
                            .fill(.white.opacity(0.4))
                            .frame(width: 20, height: 2)
                    }
                    
                    Spacer()
                    
                    // Mock content lines
                    VStack(spacing: 2) {
                        ForEach(0..<3, id: \.self) { _ in
                            HStack {
                                Rectangle()
                                    .fill(.white.opacity(0.3))
                                    .frame(height: 1)
                                
                                Rectangle()
                                    .fill(.white.opacity(0.2))
                                    .frame(width: 15, height: 1)
                            }
                        }
                    }
                    
                    Spacer()
                }
                .padding(8)
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
    }
}

private struct Badge: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption2)
            .fontWeight(.medium)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(color.opacity(0.2))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }
}

private struct FeatureIcon: View {
    let systemName: String
    let color: Color
    
    var body: some View {
        Image(systemName: systemName)
            .font(.caption)
            .foregroundStyle(color)
            .frame(width: 16, height: 16)
    }
}

// MARK: - Supporting Types

private enum TemplateFilterCategory: CaseIterable {
    case all
    case professional
    case creative
    case minimal
    case service
    case product
    case themed
    case enhanced
    case custom
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .professional: return "Professional"
        case .creative: return "Creative"
        case .minimal: return "Minimal"
        case .service: return "Service"
        case .product: return "Product"
        case .themed: return "Themed"
        case .enhanced: return "Enhanced"
        case .custom: return "Custom"
        }
    }
}


// MARK: - Template Preview View

private struct TemplatePreviewView: View {
    @Environment(\.dismiss) private var dismiss
    
    let template: InvoiceTemplate
    let onSelect: (InvoiceTemplate) -> Void
    let onDuplicate: (InvoiceTemplate) -> Void
    
    @State private var showingDuplicateAlert = false
    @State private var duplicateName = ""
    @State private var showingCustomization = false
    @State private var currentTemplate: InvoiceTemplate
    
    init(template: InvoiceTemplate, onSelect: @escaping (InvoiceTemplate) -> Void, onDuplicate: @escaping (InvoiceTemplate) -> Void) {
        self.template = template
        self.onSelect = onSelect
        self.onDuplicate = onDuplicate
        self._currentTemplate = State(initialValue: template)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Template info
                    templateInfoSection
                    
                    // Full preview
                    templatePreviewSection
                }
                .padding()
            }
            .navigationTitle(template.displayName)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: {
                    #if os(iOS)
                    .topBarLeading
                    #else
                    .cancellationAction
                    #endif
                }()) {
                    Button("Close") { dismiss() }
                }
                
                ToolbarItem(placement: {
                    #if os(iOS)
                    .topBarTrailing
                    #else
                    .primaryAction
                    #endif
                }()) {
                    Menu {
                        Button {
                            onSelect(currentTemplate)
                        } label: {
                            Label("Select Template", systemImage: "checkmark.circle")
                        }
                        
                        Button {
                            showingCustomization = true
                        } label: {
                            Label("Customize", systemImage: "slider.horizontal.3")
                        }
                        
                        if !template.isCustom {
                            Button {
                                duplicateName = "\(template.displayName) Copy"
                                showingDuplicateAlert = true
                            } label: {
                                Label("Duplicate", systemImage: "doc.on.doc")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .alert("Duplicate Template", isPresented: $showingDuplicateAlert) {
                TextField("Template Name", text: $duplicateName)
                
                Button("Cancel", role: .cancel) { }
                
                Button("Duplicate") {
                    onDuplicate(template)
                }
                .disabled(duplicateName.isEmpty)
            } message: {
                Text("Enter a name for the duplicated template.")
            }
            .sheet(isPresented: $showingCustomization) {
                TemplateCustomizationView(template: currentTemplate) { customizedTemplate in
                    currentTemplate = customizedTemplate
                }
                #if os(macOS)
                .frame(minWidth: 900, minHeight: 700)
                #endif
            }
        }
    }
    
    @ViewBuilder
    private var templateInfoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Template Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if template.isDefault {
                    Badge(text: "Default", color: .yellow)
                } else if template.isCustom {
                    Badge(text: "Custom", color: .blue)
                }
            }
            
            if let description = template.templateDescription {
                Text(description)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            // Template properties
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                PropertyRow(title: "Header Style", value: currentTemplate.headerLayout.displayName)
                PropertyRow(title: "Footer Style", value: currentTemplate.footerLayout.displayName)
                PropertyRow(title: "Logo Position", value: currentTemplate.logoPosition.displayName)
                PropertyRow(title: "Font Size", value: "\(currentTemplate.fontSize)pt")
            }
            
            // Color scheme
            VStack(alignment: .leading, spacing: 8) {
                Text("Color Scheme")
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 12) {
                    ColorSwatch(color: currentTemplate.primaryColorSwiftUI(), label: "Primary")
                    ColorSwatch(color: currentTemplate.secondaryColorSwiftUI(), label: "Secondary")
                    ColorSwatch(color: currentTemplate.accentColorSwiftUI(), label: "Accent")
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var templatePreviewSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.semibold)
            
            // Create a mock InvoiceTemplateService to generate preview
            // Since the service is temporarily disabled, we'll show a basic preview
            VStack(spacing: 16) {
                // Header preview
                HStack {
                    VStack(alignment: .leading) {
                        Text("Your Business Name")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundStyle(currentTemplate.primaryColorSwiftUI())
                        
                        Text("123 Business St, City, State")
                            .font(.caption)
                            .foregroundStyle(currentTemplate.secondaryColorSwiftUI())
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text("INVOICE")
                            .font(.title)
                            .fontWeight(.heavy)
                            .foregroundStyle(currentTemplate.accentColorSwiftUI())
                        
                        Text("INV-0001")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
                .padding()
                
                Divider()
                    .foregroundStyle(currentTemplate.secondaryColorSwiftUI())
                
                // Sample invoice items
                VStack(spacing: 8) {
                    HStack {
                        Text("Description")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("Qty")
                            .fontWeight(.semibold)
                            .frame(width: 40)
                        Text("Rate")
                            .fontWeight(.semibold)
                            .frame(width: 60, alignment: .trailing)
                        Text("Amount")
                            .fontWeight(.semibold)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption)
                    .foregroundStyle(currentTemplate.secondaryColorSwiftUI())
                    .padding(.horizontal)
                    .padding(.vertical, 4)
                    .background(currentTemplate.primaryColorSwiftUI().opacity(0.1))
                    
                    HStack {
                        Text("Consulting Services")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("10")
                            .frame(width: 40)
                        Text("$150")
                            .frame(width: 60, alignment: .trailing)
                        Text("$1,500")
                            .fontWeight(.semibold)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                    
                    HStack {
                        Text("Design Work")
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text("5")
                            .frame(width: 40)
                        Text("$120")
                            .frame(width: 60, alignment: .trailing)
                        Text("$600")
                            .fontWeight(.semibold)
                            .frame(width: 70, alignment: .trailing)
                    }
                    .font(.caption)
                    .padding(.horizontal)
                }
                
                Spacer()
                
                // Total section
                VStack(spacing: 4) {
                    HStack {
                        Spacer()
                        VStack(alignment: .trailing, spacing: 2) {
                            HStack {
                                Text("Subtotal:")
                                Spacer()
                                Text("$2,100")
                            }
                            if currentTemplate.showTaxColumn {
                                HStack {
                                    Text("Tax:")
                                    Spacer()
                                    Text("$210")
                                }
                            }
                            Divider()
                            HStack {
                                Text("Total:")
                                    .fontWeight(.bold)
                                Spacer()
                                Text("$2,310")
                                    .fontWeight(.bold)
                                    .foregroundStyle(currentTemplate.accentColorSwiftUI())
                            }
                        }
                        .font(.caption)
                        .frame(width: 150)
                    }
                }
                .padding()
            }
            .frame(height: 400)
            .background(.white)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
        }
    }
}

private struct PropertyRow: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.medium)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct ColorSwatch: View {
    let color: Color
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 24, height: 24)
                .overlay(
                    Circle()
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
            
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Create Template View

/*
private struct CreateTemplateView: View {
    @Environment(\.dismiss) private var dismiss
    
    let templateService: InvoiceTemplateService
    let onTemplateCreated: (InvoiceTemplate) -> Void
    
    @State private var templateName = ""
    @State private var displayName = ""
    @State private var description = ""
    @State private var selectedBaseTemplate: InvoiceTemplate = .classic
    @State private var isCreating = false
    @State private var error: Error?
    @State private var showingError = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Template Information") {
                    TextField("Template Name", text: $templateName)
                        .autocorrectionDisabled()
                    
                    TextField("Display Name", text: $displayName)
                    
                    TextField("Description (Optional)", text: $description, axis: .vertical)
                        .lineLimit(3...6)
                }
                
                Section("Base Template") {
                    Picker("Base Template", selection: $selectedBaseTemplate) {
                        ForEach(InvoiceTemplate.builtInTemplates) { template in
                            Text(template.displayName)
                                .tag(template)
                        }
                    }
                    .pickerStyle(.navigationLink)
                    
                    Text("Your custom template will start with the styling and layout of the selected base template.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Create Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Create") {
                        createTemplate()
                    }
                    .disabled(templateName.isEmpty || displayName.isEmpty || isCreating)
                }
            }
            .alert("Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(error?.localizedDescription ?? "An unknown error occurred")
            }
        }
    }
    
    private func createTemplate() {
        Task {
            isCreating = true
            
            do {
                let newTemplate = try await templateService.createCustomTemplate(
                    name: templateName.lowercased().replacingOccurrences(of: " ", with: "_"),
                    displayName: displayName,
                    description: description.isEmpty ? nil : description,
                    baseTemplate: selectedBaseTemplate
                )
                
                onTemplateCreated(newTemplate)
                dismiss()
            } catch {
                self.error = error
                showingError = true
            }
            
            isCreating = false
        }
    }
}
*/

#Preview {
    TemplateSelectionView { template in
        print("Selected template: \(template.displayName)")
    }
    .modelContainer(SwiftDataStack.shared.modelContainer)
}