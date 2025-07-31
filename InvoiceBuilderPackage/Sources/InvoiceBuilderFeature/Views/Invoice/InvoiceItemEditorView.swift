import SwiftUI
import SwiftData

@MainActor
public struct InvoiceItemEditorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @Query private var serviceItems: [ServiceItemEntity]
    
    // Item data
    @State private var itemName: String = ""
    @State private var itemDescription: String = ""
    @State private var quantity: Double = 1.0
    @State private var rate: Double = 0.0
    @State private var taxRate: Double = 0.0
    
    // UI State
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var showingServiceItemPicker = false
    
    private let existingItem: InvoiceItem?
    private let businessProfile: BusinessProfile?
    private let onSave: (InvoiceItem) -> Void
    
    private var isEditing: Bool {
        existingItem != nil
    }
    
    private var calculatedTotal: Decimal {
        let itemTotal = Decimal(quantity) * Decimal(rate)
        let taxAmount = itemTotal * (Decimal(taxRate) / 100)
        return itemTotal + taxAmount
    }
    
    public init(
        item: InvoiceItem? = nil,
        businessProfile: BusinessProfile? = nil,
        onSave: @escaping (InvoiceItem) -> Void
    ) {
        self.existingItem = item
        self.businessProfile = businessProfile
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    if !serviceItems.isEmpty && !isEditing {
                        quickAddSection
                    }
                    itemDetailsSection
                    pricingSection
                    taxSection
                    totalSection
                }
                .padding()
            }
            .navigationTitle(isEditing ? "Edit Item" : "Add Item")
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
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: {
                    #if os(iOS)
                    .topBarTrailing
                    #else
                    .primaryAction
                    #endif
                }()) {
                    Button(isEditing ? "Update" : "Add") {
                        saveItem()
                    }
                    .disabled(itemName.isEmpty || rate <= 0)
                }
            }
            .task {
                loadItemData()
            }
        }
        .sheet(isPresented: $showingServiceItemPicker) {
            ServiceItemPickerView(
                serviceItems: serviceItems.map { ServiceItem(from: $0) }
            ) { selectedServiceItem in
                // Populate form with selected service item
                itemName = selectedServiceItem.name
                itemDescription = selectedServiceItem.description ?? ""
                rate = Double(truncating: selectedServiceItem.defaultRate as NSDecimalNumber)
                showingServiceItemPicker = false
            }
        }
        .alert("Validation Error", isPresented: $showingValidationError) {
            Button("OK") { }
        } message: {
            Text(validationMessage)
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var itemDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Item Details")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Item Name *")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g., Web Design", text: $itemName)
                        .textFieldStyle(.roundedBorder)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Description")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Optional description", text: $itemDescription, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(2...4)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var pricingSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Pricing")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Quantity *")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("1.0", value: $quantity, format: .number)
                        .textFieldStyle(.roundedBorder)
                        #if os(iOS)
                        .keyboardType(.decimalPad)
                        #endif
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Rate *")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        Text("$")
                            .foregroundStyle(.secondary)
                        TextField("0.00", value: $rate, format: .number)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                    }
                }
            }
            
            HStack {
                Text("Subtotal:")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                Spacer()
                
                Text(formatCurrency(Decimal(quantity) * Decimal(rate)))
                    .font(.subheadline)
                    .fontWeight(.medium)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var taxSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Tax")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let businessProfile = businessProfile,
                   businessProfile.defaultTaxRate > 0 {
                    Button("Use Default (\(String(format: "%.1f", Double(truncating: businessProfile.defaultTaxRate as NSNumber)))%)") {
                        taxRate = Double(truncating: businessProfile.defaultTaxRate as NSNumber)
                    }
                    .font(.caption)
                    .foregroundStyle(.blue)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Tax Rate (%)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                TextField("0.0", value: $taxRate, format: .number)
                    .textFieldStyle(.roundedBorder)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
            }
            
            if taxRate > 0 {
                HStack {
                    Text("Tax Amount:")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text(formatCurrency((Decimal(quantity) * Decimal(rate)) * (Decimal(taxRate) / 100)))
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var totalSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Total")
                .font(.headline)
                .fontWeight(.semibold)
            
            HStack {
                Text("Item Total:")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(formatCurrency(calculatedTotal))
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(.blue)
            }
            
            if taxRate > 0 {
                Text("Includes \(String(format: "%.1f", taxRate))% tax")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var quickAddSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "rectangle.3.group")
                    .foregroundStyle(.blue)
                Text("Quick Add")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(serviceItems.count) items available")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Button {
                showingServiceItemPicker = true
            } label: {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Select from Service Library")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Text("Choose from your pre-configured service items")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 12)
                .padding(.horizontal, 16)
                .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Private Methods
    
    private func loadItemData() {
        guard let item = existingItem else { return }
        
        itemName = item.name
        itemDescription = item.description
        quantity = Double(truncating: item.quantity as NSNumber)
        rate = Double(truncating: item.rate as NSNumber)
        taxRate = Double(truncating: item.taxRate as NSNumber)
    }
    
    private func saveItem() {
        // Validation
        guard !itemName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            validationMessage = "Item name is required"
            showingValidationError = true
            return
        }
        
        guard quantity > 0 else {
            validationMessage = "Quantity must be greater than 0"
            showingValidationError = true
            return
        }
        
        guard rate > 0 else {
            validationMessage = "Rate must be greater than 0"
            showingValidationError = true
            return
        }
        
        guard taxRate >= 0 && taxRate <= 100 else {
            validationMessage = "Tax rate must be between 0% and 100%"
            showingValidationError = true
            return
        }
        
        // Create the invoice item
        let item = InvoiceItem(
            id: existingItem?.id ?? UUID(),
            name: itemName.trimmingCharacters(in: .whitespacesAndNewlines),
            description: itemDescription.trimmingCharacters(in: .whitespacesAndNewlines),
            quantity: Decimal(quantity),
            rate: Decimal(rate),
            taxRate: Decimal(taxRate)
        )
        
        onSave(item)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        if let businessProfile = businessProfile {
            return businessProfile.currency.formatAmount(amount)
        }
        // Fallback to USD if no business profile
        return Currency.usd.formatAmount(amount)
    }
}

#Preview {
    InvoiceItemEditorView { item in
        print("Saved item: \(item.name)")
    }
}