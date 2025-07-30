import SwiftUI
import SwiftData

public struct ItemDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var item: ServiceItem
    @State private var isEditing: Bool
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    @State private var showingIconPicker = false
    
    // Form validation
    private var isFormValid: Bool {
        !item.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        item.defaultRate > 0
    }
    
    private var isNewItem: Bool {
        isEditing && serviceItemExists() == nil
    }
    
    public init(item: ServiceItem? = nil) {
        if let item = item {
            self._item = State(initialValue: item)
            self._isEditing = State(initialValue: false)
        } else {
            self._item = State(initialValue: ServiceItem(
                name: "",
                description: "",
                defaultRate: 0,
                category: "",
                iconName: nil
            ))
            self._isEditing = State(initialValue: true)
        }
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                pricingSection
                categorizationSection
                
                if !isNewItem && !isEditing {
                    metadataSection
                }
                
                if !isNewItem && isEditing {
                    deleteSection
                }
            }
            .navigationTitle(isNewItem ? "New Service Item" : (isEditing ? "Edit Item" : item.name))
            #if os(iOS)
            .navigationBarTitleDisplayMode(isNewItem ? .inline : .large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isNewItem ? "Cancel" : "Done") {
                        if isNewItem || !isEditing {
                            dismiss()
                        } else {
                            isEditing = false
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveItem()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                    } else if !isNewItem {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .confirmationDialog(
                "Delete Service Item",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: item
            ) { item in
                Button("Delete Item", role: .destructive) {
                    deleteItem()
                }
                Button("Cancel", role: .cancel) { }
            } message: { item in
                Text("Are you sure you want to delete \"\(item.name)\"? This action cannot be undone.")
            }
            .sheet(isPresented: $showingIconPicker) {
                IconPickerView { iconName in
                    item.iconName = iconName
                    showingIconPicker = false
                }
            }
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Form Sections
    
    @ViewBuilder
    private var basicInfoSection: some View {
        Section("Service Information") {
            ItemFormField(
                title: "Service Name",
                text: $item.name,
                placeholder: "Web Development",
                isRequired: true,
                isEditing: isEditing
            )
            
            ItemFormField(
                title: "Description",
                text: Binding(
                    get: { item.description ?? "" },
                    set: { item.description = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "Custom website development and design",
                isEditing: isEditing,
                axis: .vertical,
                lineLimit: 3
            )
        }
    }
    
    @ViewBuilder
    private var pricingSection: some View {
        Section("Pricing") {
            if isEditing {
                HStack {
                    Text("Default Rate")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    TextField("0.00", value: $item.defaultRate, format: .currency(code: "USD"))
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 120)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
            } else {
                HStack {
                    Text("Default Rate")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(formatCurrency(item.defaultRate))
                        .fontWeight(.medium)
                }
            }
            
            if !isEditing {
                Text("This rate will be used as the default when adding this item to invoices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var categorizationSection: some View {
        Section("Organization") {
            // Category
            if isEditing {
                HStack {
                    Text("Category")
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    TextField("Optional", text: Binding(
                        get: { item.category ?? "" },
                        set: { item.category = $0.isEmpty ? nil : $0 }
                    ))
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                }
            } else if let category = item.category, !category.isEmpty {
                HStack {
                    Text("Category")
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(category)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(.blue.opacity(0.1))
                        .foregroundStyle(.blue)
                        .cornerRadius(4)
                }
            }
            
            // Icon
            HStack {
                Text("Icon")
                    .fontWeight(.medium)
                
                Spacer()
                
                if let iconName = item.iconName, !iconName.isEmpty {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 30, height: 30)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(6)
                } else {
                    Image(systemName: "rectangle.3.group")
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .frame(width: 30, height: 30)
                        .background(.gray.opacity(0.1))
                        .cornerRadius(6)
                }
                
                if isEditing {
                    Button("Change") {
                        showingIconPicker = true
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
        }
    }
    
    @ViewBuilder
    private var metadataSection: some View {
        Section("Information") {
            HStack {
                Text("Created")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(item.createdAt, style: .date)
            }
            
            if item.updatedAt != item.createdAt {
                HStack {
                    Text("Last Updated")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(item.updatedAt, style: .date)
                }
            }
        }
    }
    
    @ViewBuilder
    private var deleteSection: some View {
        Section {
            Button("Delete Service Item") {
                showingDeleteConfirmation = true
            }
            .foregroundStyle(.red)
            .frame(maxWidth: .infinity, alignment: .center)
        }
    }
    
    // MARK: - Methods
    
    private func saveItem() {
        isLoading = true
        
        Task {
            await saveToDatabase()
            
            await MainActor.run {
                isLoading = false
                if isNewItem {
                    dismiss()
                } else {
                    isEditing = false
                }
            }
        }
    }
    
    private func deleteItem() {
        isLoading = true
        
        Task {
            await deleteFromDatabase()
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
    
    private func saveToDatabase() async {
        do {
            if let existingEntity = serviceItemExists() {
                // Update existing
                updateServiceItemEntity(existingEntity, with: item)
            } else {
                // Create new
                let newEntity = ServiceItemEntity(
                    id: item.id,
                    name: item.name.trimmingCharacters(in: .whitespacesAndNewlines),
                    itemDescription: item.description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    defaultRate: item.defaultRate,
                    category: item.category?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty,
                    iconName: item.iconName?.nilIfEmpty,
                    isActive: item.isActive,
                    sortOrder: item.sortOrder
                )
                
                // Get or create business profile and associate
                let businessProfile = try getOrCreateBusinessProfile()
                newEntity.businessProfile = businessProfile
                
                modelContext.insert(newEntity)
            }
            
            try modelContext.save()
        } catch {
            print("Failed to save service item: \(error)")
        }
    }
    
    private func deleteFromDatabase() async {
        guard let entity = serviceItemExists() else { return }
        
        do {
            modelContext.delete(entity)
            try modelContext.save()
        } catch {
            print("Failed to delete service item: \(error)")
        }
    }
    
    private func serviceItemExists() -> ServiceItemEntity? {
        let itemId = item.id
        let descriptor = FetchDescriptor<ServiceItemEntity>(
            predicate: #Predicate<ServiceItemEntity> { entity in
                entity.id == itemId
            }
        )
        
        do {
            let results = try modelContext.fetch(descriptor)
            return results.first
        } catch {
            print("Failed to check if service item exists: \(error)")
            return nil
        }
    }
    
    private func updateServiceItemEntity(_ entity: ServiceItemEntity, with item: ServiceItem) {
        entity.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
        entity.itemDescription = item.description?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        entity.defaultRate = item.defaultRate
        entity.category = item.category?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        entity.iconName = item.iconName?.nilIfEmpty
        entity.isActive = item.isActive
        entity.sortOrder = item.sortOrder
        entity.updatedAt = Date()
    }
    
    private func getOrCreateBusinessProfile() throws -> BusinessProfileEntity {
        let descriptor = FetchDescriptor<BusinessProfileEntity>()
        let profiles = try modelContext.fetch(descriptor)
        
        if let existingProfile = profiles.first {
            return existingProfile
        } else {
            let newProfile = BusinessProfileEntity(
                businessName: "",
                ownerName: "",
                email: ""
            )
            modelContext.insert(newProfile)
            return newProfile
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // TODO: Get from business profile
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Supporting Views

private struct ItemFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isRequired: Bool = false
    let isEditing: Bool
    var axis: Axis = .horizontal
    var lineLimit: Int = 1
    
    var body: some View {
        if isEditing {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(title)
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    if isRequired {
                        Text("*")
                            .foregroundStyle(.red)
                    }
                }
                
                TextField(placeholder, text: $text, axis: axis)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(lineLimit, reservesSpace: axis == .vertical)
            }
        } else if !text.isEmpty {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(text)
                    .multilineTextAlignment(.trailing)
            }
        }
    }
}

private struct IconPickerView: View {
    let onIconSelected: (String) -> Void
    @Environment(\.dismiss) private var dismiss
    
    private let icons = [
        "rectangle.3.group", "person.2.fill", "paintbrush.fill", "laptopcomputer",
        "megaphone.fill", "doc.text.fill", "camera.fill", "scale.3d",
        "dollarsign.circle.fill", "wrench.and.screwdriver.fill", "car.fill",
        "house.fill", "leaf.fill", "heart.fill", "star.fill", "gear",
        "lightbulb.fill", "phone.fill", "envelope.fill", "calendar",
        "clock.fill", "map.fill", "gift.fill", "gamecontroller.fill"
    ]
    
    var body: some View {
        NavigationStack {
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 6), spacing: 16) {
                ForEach(icons, id: \.self) { iconName in
                    Button {
                        onIconSelected(iconName)
                    } label: {
                        Image(systemName: iconName)
                            .font(.title2)
                            .foregroundStyle(.blue)
                            .frame(width: 44, height: 44)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
            }
            .padding()
            .navigationTitle("Choose Icon")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - String Extension

private extension String {
    var nilIfEmpty: String? {
        isEmpty ? nil : self
    }
}

#Preview {
    ItemDetailView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}