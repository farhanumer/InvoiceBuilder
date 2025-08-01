import SwiftUI
import SwiftData

@MainActor
public struct InvoiceBuilderView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(InvoiceTemplateService.self) private var templateService
    
    @Query private var businessProfiles: [BusinessProfileEntity]
    @Query private var clients: [ClientEntity]
    
    // Invoice data
    @State private var invoiceNumber: String = ""
    @State private var issueDate = Date()
    @State private var dueDate = Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date()
    @State private var selectedClient: Client?
    @State private var poNumber: String = ""
    @State private var notes: String = ""
    @State private var paymentTerms: String = ""
    
    // Line items
    @State private var invoiceItems: [InvoiceItem] = []
    
    // Discount
    @State private var discountAmount: Double = 0.0
    @State private var discountType: DiscountType = .fixed
    
    // UI State
    @State private var showingClientPicker = false
    @State private var showingTemplatePicker = false
    @State private var showingItemEditor = false
    @State private var editingItemIndex: Int?
    @State private var showingPreview = false
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var showingErrorAlert = false
    
    // Current template
    @State private var selectedTemplate: InvoiceTemplate = .classic
    
    // Initialize with existing invoice for editing
    private let existingInvoice: Invoice?
    private let onSave: ((Invoice) -> Void)?
    
    public init(existingInvoice: Invoice? = nil, onSave: ((Invoice) -> Void)? = nil) {
        self.existingInvoice = existingInvoice
        self.onSave = onSave
    }
    
    public var body: some View {
        NavigationStack {
            #if os(macOS)
            // macOS always uses side-by-side layout
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    // Editor pane
                    ScrollView {
                        VStack(spacing: 20) {
                            invoiceDetailsSection
                            clientSection
                            itemsSection
                            calculationsSection
                            additionalInfoSection
                        }
                        .padding()
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.controlBackgroundColor))
                    
                    Divider()
                    
                    // Preview pane
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Preview")
                                .font(.headline)
                                .fontWeight(.semibold)
                                .padding(.horizontal)
                            
                            if let client = selectedClient, !invoiceItems.isEmpty,
                               let businessProfile = businessProfiles.first.map({ BusinessProfile(from: $0) }) {
                                
                                let previewInvoice = createPreviewInvoice(client: client)
                                
                                templateService.renderInvoicePreview(
                                    invoice: previewInvoice,
                                    businessProfile: businessProfile,
                                    template: selectedTemplate
                                )
                                .padding()
                            } else {
                                VStack(spacing: 16) {
                                    Image(systemName: "doc.text")
                                        .font(.system(size: 48))
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Preview will appear here")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                    
                                    Text("Add a client and items to see the invoice preview")
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .padding()
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .background(Color(.textBackgroundColor))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            #else
            // iOS uses responsive layout based on screen size
            GeometryReader { geometry in
                if geometry.size.width > 800 {
                    // iPad layout - side by side
                    HStack(spacing: 0) {
                        // Editor pane
                        ScrollView {
                            VStack(spacing: 20) {
                                invoiceDetailsSection
                                clientSection
                                itemsSection
                                calculationsSection
                                additionalInfoSection
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .frame(width: geometry.size.width * 0.5)
                        .frame(maxHeight: .infinity)
                        
                        Divider()
                        
                        // Preview pane
                        invoicePreviewSection
                            .frame(width: geometry.size.width * 0.5)
                            .frame(maxHeight: .infinity)
                    }
                } else {
                    // iPhone layout - tabs
                    TabView {
                        // Editor tab
                        ScrollView {
                            VStack(spacing: 20) {
                                invoiceDetailsSection
                                clientSection
                                itemsSection
                                calculationsSection
                                additionalInfoSection
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tabItem {
                            Label("Edit", systemImage: "pencil")
                        }
                        
                        // Preview tab
                        invoicePreviewSection
                            .tabItem {
                                Label("Preview", systemImage: "eye")
                            }
                    }
                }
            }
            #endif
        }
        .navigationTitle(existingInvoice == nil ? "New Invoice" : "Edit Invoice")
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
                    Button(existingInvoice == nil ? "Save" : "Update") {
                        saveInvoice()
                    }
                    .disabled(selectedClient == nil || invoiceItems.isEmpty)
                }
            }
        .task {
            await loadInitialData()
        }
        .sheet(isPresented: $showingClientPicker) {
            ClientPickerView(clients: clients.map { Client(from: $0) }) { client in
                selectedClient = client
                showingClientPicker = false
            }
        }
        .sheet(isPresented: $showingTemplatePicker) {
            TemplateSelectionView { template in
                selectedTemplate = template
                templateService.selectTemplate(template)
                showingTemplatePicker = false
            }
        }
        .sheet(isPresented: $showingItemEditor) {
            InvoiceItemEditorView(
                item: editingItemIndex != nil ? invoiceItems[editingItemIndex!] : nil,
                businessProfile: businessProfiles.first.map { BusinessProfile(from: $0) }
            ) { item in
                if let index = editingItemIndex {
                    invoiceItems[index] = item
                } else {
                    invoiceItems.append(item)
                }
                showingItemEditor = false
                editingItemIndex = nil
            }
        }
        .alert("Error", isPresented: $showingErrorAlert) {
            Button("OK") { }
        } message: {
            Text(errorMessage ?? "An unknown error occurred")
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var invoiceDetailsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Invoice Details")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    showingTemplatePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text("Template")
                        Text(selectedTemplate.displayName)
                            .fontWeight(.medium)
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.blue)
                }
            }
            
            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Invoice Number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("INV-0001", text: $invoiceNumber)
                            .textFieldStyle(.roundedBorder)
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("PO Number")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        TextField("Optional", text: $poNumber)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Issue Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $issueDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Due Date")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        DatePicker("", selection: $dueDate, displayedComponents: .date)
                            .datePickerStyle(.compact)
                            .labelsHidden()
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var clientSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Bill To")
                .font(.headline)
                .fontWeight(.semibold)
            
            if let client = selectedClient {
                ClientSummaryCard(client: client) {
                    showingClientPicker = true
                }
            } else {
                Button {
                    showingClientPicker = true
                } label: {
                    VStack(spacing: 12) {
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 24))
                            .foregroundStyle(.blue)
                        
                        Text("Select Client")
                            .font(.headline)
                            .foregroundStyle(.blue)
                        
                        Text("Choose a client to bill for this invoice")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                    .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Items")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button {
                    editingItemIndex = nil
                    showingItemEditor = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .foregroundStyle(.blue)
                }
            }
            
            if invoiceItems.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet.rectangle")
                        .font(.system(size: 24))
                        .foregroundStyle(.secondary)
                    
                    Text("No items added")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add items to your invoice to get started")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 20)
            } else {
                VStack(spacing: 1) {
                    ForEach(Array(invoiceItems.enumerated()), id: \.offset) { index, item in
                        InvoiceItemRow(
                            item: item,
                            currency: businessProfiles.first.map { BusinessProfile(from: $0).currency } ?? .usd,
                            onEdit: {
                                editingItemIndex = index
                                showingItemEditor = true
                            },
                            onDelete: {
                                invoiceItems.remove(at: index)
                            }
                        )
                    }
                }
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var calculationsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Calculations")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discount")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    HStack {
                        TextField("0.0", value: $discountAmount, format: .number)
                            .textFieldStyle(.roundedBorder)
                            #if os(iOS)
                            .keyboardType(.decimalPad)
                            #endif
                        
                        Picker("Type", selection: $discountType) {
                            Text("$").tag(DiscountType.fixed)
                            Text("%").tag(DiscountType.percentage)
                        }
                        .pickerStyle(.segmented)
                        .frame(width: 60)
                    }
                }
                
                // Totals display
                VStack(spacing: 8) {
                    HStack {
                        Text("Subtotal")
                        Spacer()
                        Text(formatCurrency(calculateSubtotal()))
                            .fontWeight(.medium)
                    }
                    .font(.subheadline)
                    
                    let totalTaxAmount = calculateTaxAmount()
                    if totalTaxAmount > 0 {
                        HStack {
                            Text("Tax")
                            Spacer()
                            Text(formatCurrency(totalTaxAmount))
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                    }
                    
                    if discountAmount > 0 {
                        HStack {
                            Text("Discount")
                            Spacer()
                            Text("-\(formatCurrency(calculateDiscountAmount()))")
                                .fontWeight(.medium)
                                .foregroundStyle(.orange)
                        }
                        .font(.subheadline)
                    }
                    
                    Divider()
                    
                    HStack {
                        Text("Total")
                            .font(.headline)
                            .fontWeight(.bold)
                        Spacer()
                        Text(formatCurrency(calculateTotal()))
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundStyle(.blue)
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Additional Information")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("Optional notes or terms", text: $notes, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Terms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    TextField("e.g., Net 30", text: $paymentTerms)
                        .textFieldStyle(.roundedBorder)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var invoicePreviewSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preview")
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.horizontal)
            
            if let client = selectedClient, !invoiceItems.isEmpty,
               let businessProfile = businessProfiles.first.map({ BusinessProfile(from: $0) }) {
                
                let previewInvoice = createPreviewInvoice(client: client)
                
                ScrollView {
                    templateService.renderInvoicePreview(
                        invoice: previewInvoice,
                        businessProfile: businessProfile,
                        template: selectedTemplate
                    )
                    .padding()
                }
            } else {
                VStack(spacing: 16) {
                    Image(systemName: "doc.text")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    
                    Text("Preview will appear here")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                    
                    Text("Add a client and items to see the invoice preview")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding()
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func loadInitialData() async {
        if let existingInvoice = existingInvoice {
            // Load existing invoice data
            invoiceNumber = existingInvoice.invoiceNumber
            issueDate = existingInvoice.date
            dueDate = existingInvoice.dueDate
            selectedClient = existingInvoice.client
            poNumber = existingInvoice.poNumber ?? ""
            notes = existingInvoice.notes ?? ""
            paymentTerms = existingInvoice.paymentTerms ?? ""
            invoiceItems = existingInvoice.items
            
            // Note: Tax rates are now handled per-item, not at invoice level
            
            if existingInvoice.discountAmount > 0 {
                discountAmount = Double(truncating: existingInvoice.discountAmount as NSNumber)
                // For now, assume fixed discount - could be enhanced to detect type
                discountType = .fixed
            }
        } else {
            // Generate new invoice number
            await generateInvoiceNumber()
        }
    }
    
    private func generateInvoiceNumber() async {
        guard let businessProfile = businessProfiles.first else {
            invoiceNumber = "INV-0001"
            return
        }
        
        let profile = BusinessProfile(from: businessProfile)
        invoiceNumber = profile.generateNextInvoiceNumber()
    }
    
    private func createPreviewInvoice(client: Client) -> Invoice {
        var invoice = Invoice(
            invoiceNumber: invoiceNumber.isEmpty ? "INV-0001" : invoiceNumber,
            date: issueDate,
            dueDate: dueDate,
            client: client,
            items: invoiceItems
        )
        
        // Set additional properties
        invoice.poNumber = poNumber.isEmpty ? nil : poNumber
        invoice.notes = notes.isEmpty ? nil : notes
        invoice.terms = paymentTerms.isEmpty ? nil : paymentTerms
        
        // Apply tax and discount
        let subtotal = calculateSubtotal()
        let taxAmount = calculateTaxAmount()
        let discountAmountValue = calculateDiscountAmount()
        
        // Update invoice with calculated values
        invoice.updateTotals(
            subtotal: subtotal,
            taxAmount: taxAmount,
            discountAmount: discountAmountValue
        )
        
        return invoice
    }
    
    private func calculateSubtotal() -> Decimal {
        return invoiceItems.reduce(0) { total, item in
            total + item.subtotal
        }
    }
    
    private func calculateTaxAmount() -> Decimal {
        return invoiceItems.reduce(0) { total, item in
            total + item.taxAmount
        }
    }
    
    private func calculateDiscountAmount() -> Decimal {
        let subtotal = calculateSubtotal()
        let discount = Decimal(discountAmount)
        
        switch discountType {
        case .fixed:
            return min(discount, subtotal) // Don't allow discount to exceed subtotal
        case .percentage:
            return subtotal * (discount / 100)
        }
    }
    
    private func calculateTotal() -> Decimal {
        let subtotal = calculateSubtotal()
        let tax = calculateTaxAmount()
        let discount = calculateDiscountAmount()
        
        return max(0, subtotal + tax - discount)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        guard let businessProfile = businessProfiles.first else {
            // Fallback to USD if no business profile
            return Currency.usd.formatAmount(amount)
        }
        
        let profile = BusinessProfile(from: businessProfile)
        return profile.currency.formatAmount(amount)
    }
    
    private func saveInvoice() {
        guard let client = selectedClient else {
            errorMessage = "Please select a client"
            showingErrorAlert = true
            return
        }
        
        guard !invoiceItems.isEmpty else {
            errorMessage = "Please add at least one item"
            showingErrorAlert = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let invoice = createPreviewInvoice(client: client)
                
                if existingInvoice != nil {
                    // Update existing invoice
                    try await updateInvoice(invoice)
                } else {
                    // Create new invoice
                    try await createNewInvoice(invoice)
                    
                    // Update business profile with next invoice number
                    await updateBusinessProfileInvoiceNumber()
                }
                
                await MainActor.run {
                    isLoading = false
                    onSave?(invoice)
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    errorMessage = "Failed to save invoice: \(error.localizedDescription)"
                    showingErrorAlert = true
                }
            }
        }
    }
    
    private func createNewInvoice(_ invoice: Invoice) async throws {
        let entity = InvoiceEntity(
            id: invoice.id,
            number: invoice.invoiceNumber,
            issueDate: invoice.date,
            dueDate: invoice.dueDate,
            status: invoice.status.rawValue,
            currency: invoice.currency.rawValue,
            subtotal: invoice.subtotal,
            taxAmount: invoice.taxAmount,
            discountAmount: invoice.discountAmount,
            totalAmount: invoice.total,
            notes: invoice.notes,
            poNumber: invoice.poNumber,
            terms: invoice.paymentTerms
        )
        
        // Set client relationship
        if let clientEntity = clients.first(where: { $0.id == invoice.client.id }) {
            entity.client = clientEntity
        }
        
        // Create item entities
        for item in invoice.items {
            let itemEntity = InvoiceItemEntity(
                id: item.id,
                itemDescription: "\(item.name): \(item.description)",
                quantity: item.quantity,
                unitPrice: item.rate,
                taxRate: item.taxRate
            )
            entity.items.append(itemEntity)
        }
        
        modelContext.insert(entity)
        try modelContext.save()
    }
    
    private func updateInvoice(_ invoice: Invoice) async throws {
        // Implementation for updating existing invoice
        // This would involve finding the existing entity and updating its properties
        // For now, we'll treat it as a new invoice creation
        try await createNewInvoice(invoice)
    }
    
    private func updateBusinessProfileInvoiceNumber() async {
        guard let businessProfileEntity = businessProfiles.first else { return }
        
        businessProfileEntity.nextInvoiceNumber += 1
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to update business profile invoice number: \(error)")
        }
    }
}

// MARK: - Supporting Types

enum DiscountType: String, CaseIterable {
    case fixed = "fixed"
    case percentage = "percentage"
    
    var displayName: String {
        switch self {
        case .fixed: return "Fixed Amount"
        case .percentage: return "Percentage"
        }
    }
}

// MARK: - Supporting Views

private struct ClientSummaryCard: View {
    let client: Client
    let onEdit: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            Group {
                if let avatarData = client.avatarData {
                    #if canImport(UIKit)
                    if let uiImage = UIImage(data: avatarData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        clientInitials
                    }
                    #elseif canImport(AppKit)
                    if let nsImage = NSImage(data: avatarData) {
                        Image(nsImage: nsImage)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } else {
                        clientInitials
                    }
                    #endif
                } else {
                    clientInitials
                }
            }
            .frame(width: 40, height: 40)
            .clipShape(Circle())
            
            // Client info
            VStack(alignment: .leading, spacing: 2) {
                Text(client.name)
                    .font(.headline)
                    .fontWeight(.medium)
                
                Text(client.email)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let company = client.company, !company.isEmpty {
                    Text(company)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            Button("Change") {
                onEdit()
            }
            .font(.caption)
            .foregroundStyle(.blue)
        }
        .padding()
        .background(.blue.opacity(0.1), in: RoundedRectangle(cornerRadius: 8))
    }
    
    @ViewBuilder
    private var clientInitials: some View {
        Circle()
            .fill(.gray.opacity(0.3))
            .overlay {
                Text(String(client.name.prefix(1)))
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
    }
}

private struct InvoiceItemRow: View {
    let item: InvoiceItem
    let currency: Currency
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                if !item.description.isEmpty && item.description != item.name {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(formatDecimal(item.quantity)) × \(formatCurrency(item.rate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                Text(formatCurrency(item.total))
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            
            Menu {
                Button("Edit") { onEdit() }
                Button("Delete", role: .destructive) { onDelete() }
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color.clear)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        return currency.formatAmount(amount)
    }
    
    private func formatDecimal(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
}

#Preview {
    InvoiceBuilderView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
        .environment(InvoiceTemplateService.shared)
}