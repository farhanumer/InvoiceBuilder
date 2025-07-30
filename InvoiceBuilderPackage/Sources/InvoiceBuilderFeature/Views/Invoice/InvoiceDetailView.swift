import SwiftUI
import SwiftData
import UIKit

public struct InvoiceDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var businessProfiles: [BusinessProfileEntity]
    
    @State private var invoice: Invoice
    @State private var showingEditView = false
    @State private var showingDeleteConfirmation = false
    @State private var showingStatusChangeOptions = false
    @State private var isLoading = false
    @State private var showingPDFExportError = false
    @State private var pdfExportErrorMessage = ""
    
    public init(invoice: Invoice) {
        self._invoice = State(initialValue: invoice)
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    invoiceHeaderSection
                    clientSection
                    itemsSection
                    totalsSection
                    additionalInfoSection
                }
                .padding()
            }
            .navigationTitle("Invoice Details")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        if invoice.status == .draft {
                            Button("Edit Invoice") {
                                showingEditView = true
                            }
                            
                            Button("Mark as Sent") {
                                updateInvoiceStatus(.sent)
                            }
                        }
                        
                        if invoice.status == .sent || invoice.isOverdue {
                            Button("Mark as Paid") {
                                updateInvoiceStatus(.paid)
                            }
                        }
                        
                        if invoice.status != .cancelled {
                            Button("Cancel Invoice") {
                                updateInvoiceStatus(.cancelled)
                            }
                        }
                        
                        Divider()
                        
                        Button("Duplicate Invoice") {
                            duplicateInvoice()
                        }
                        
                        Button("Export PDF") {
                            exportToPDF()
                        }
                        
                        Divider()
                        
                        Button("Delete Invoice", role: .destructive) {
                            showingDeleteConfirmation = true
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .sheet(isPresented: $showingEditView) {
            Text("Invoice Builder Coming Soon")
                .navigationTitle("Edit Invoice")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Cancel") { showingEditView = false }
                    }
                }
        }
        .confirmationDialog(
            "Delete Invoice",
            isPresented: $showingDeleteConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Invoice", role: .destructive) {
                deleteInvoice()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this invoice? This action cannot be undone.")
        }
        .alert("PDF Export Error", isPresented: $showingPDFExportError) {
            Button("OK") { }
        } message: {
            Text(pdfExportErrorMessage)
        }
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Sections
    
    @ViewBuilder
    private var invoiceHeaderSection: some View {
        VStack(spacing: 16) {
            // Invoice Number and Status
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Invoice")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(invoice.invoiceNumber)
                        .font(.title)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                StatusBadge(status: invoice.status, isOverdue: invoice.isOverdue)
            }
            
            // Dates
            HStack(spacing: 32) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Issue Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(invoice.date.formatted(date: .abbreviated, time: .omitted))
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Due Date")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))
                        .fontWeight(.medium)
                        .foregroundStyle(invoice.isOverdue ? .red : .primary)
                }
                
                if invoice.isOverdue {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Days Overdue")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("\(invoice.daysPastDue)")
                            .fontWeight(.medium)
                            .foregroundStyle(.red)
                    }
                }
                
                Spacer()
            }
            
            // Total Amount (Prominent)
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Total Amount")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(invoice.formattedTotal)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(.blue)
                }
                
                Spacer()
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var clientSection: some View {
        let client = invoice.client
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Bill To")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    // Avatar
                    Group {
                        if let avatarData = client.avatarData, let uiImage = UIImage(data: avatarData) {
                            Image(uiImage: uiImage)
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } else {
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
                    .frame(width: 44, height: 44)
                    .clipShape(Circle())
                    
                    // Client name and company
                    VStack(alignment: .leading, spacing: 4) {
                        Text(client.name)
                            .font(.headline)
                            .fontWeight(.medium)
                        
                        if let company = client.company, !company.isEmpty {
                            Text(company)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                
                // Contact information
                VStack(alignment: .leading, spacing: 2) {
                    Text(client.email)
                        .font(.subheadline)
                    
                    if let phone = client.phone, !phone.isEmpty {
                        Text(phone)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if let address = client.address {
                        VStack(alignment: .leading, spacing: 1) {
                            Text(address.street)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(address.city), \(address.state) \(address.postalCode)")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            if !address.country.isEmpty && address.country != "US" {
                                Text(address.country)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var itemsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Items")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 1) {
                // Header
                HStack {
                    Text("Description")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                    
                    Spacer()
                    
                    Text("Qty")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 40)
                    
                    Text("Rate")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 60)
                    
                    Text("Amount")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.secondary)
                        .frame(width: 80)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.quaternary)
                
                // Items
                ForEach(invoice.items) { item in
                    InvoiceItemDetailRow(item: item)
                }
            }
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    @ViewBuilder
    private var totalsSection: some View {
        VStack(spacing: 8) {
            HStack {
                Text("Subtotal")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(invoice.formattedSubtotal)
                    .fontWeight(.medium)
            }
            
            if invoice.taxAmount > 0 {
                HStack {
                    Text("Tax")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(invoice.formattedTaxAmount)
                        .fontWeight(.medium)
                }
            }
            
            if invoice.discountAmount > 0 {
                HStack {
                    Text("Discount")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("-\(invoice.formattedDiscountAmount)")
                        .fontWeight(.medium)
                        .foregroundStyle(.orange)
                }
            }
            
            Divider()
            
            HStack {
                Text("Total")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
                Text(invoice.formattedTotal)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.blue)
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var additionalInfoSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let poNumber = invoice.poNumber, !poNumber.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Purchase Order Number")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(poNumber)
                        .fontWeight(.medium)
                }
            }
            
            if let notes = invoice.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(notes)
                        .fontWeight(.medium)
                }
            }
            
            if let paymentTerms = invoice.paymentTerms, !paymentTerms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Terms")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(paymentTerms)
                        .fontWeight(.medium)
                }
            }
            
            // Metadata
            VStack(alignment: .leading, spacing: 8) {
                Text("Created")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(invoice.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if invoice.updatedAt != invoice.createdAt {
                    Text("Last Updated")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(invoice.updatedAt.formatted(date: .abbreviated, time: .shortened))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Methods
    
    private func updateInvoiceStatus(_ newStatus: InvoiceStatus) {
        isLoading = true
        
        Task {
            await updateStatusInDatabase(newStatus)
            
            await MainActor.run {
                invoice.updateStatus(newStatus)
                isLoading = false
            }
        }
    }
    
    private func updateStatusInDatabase(_ newStatus: InvoiceStatus) async {
        do {
            let invoiceId = invoice.id
            let descriptor = FetchDescriptor<InvoiceEntity>(
                predicate: #Predicate<InvoiceEntity> { entity in
                    entity.id == invoiceId
                }
            )
            
            let results = try modelContext.fetch(descriptor)
            if let entity = results.first {
                entity.status = newStatus.rawValue
                entity.updatedAt = Date()
                try modelContext.save()
            }
        } catch {
            print("Failed to update invoice status: \(error)")
        }
    }
    
    private func duplicateInvoice() {
        // Create a new invoice based on the current one
        invoice = Invoice(
            invoiceNumber: "", // Will be generated
            date: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            client: invoice.client,
            items: invoice.items
        )
        
        showingEditView = true
    }
    
    private func exportToPDF() {
        guard let businessProfileEntity = businessProfiles.first else {
            pdfExportErrorMessage = "No business profile found. Please complete your business profile first."
            showingPDFExportError = true
            return
        }
        
        isLoading = true
        
        Task {
            do {
                let businessProfile = BusinessProfile(from: businessProfileEntity)
                
                #if os(iOS)
                try await PDFGenerationService.shared.shareInvoicePDF(
                    invoice: invoice,
                    businessProfile: businessProfile
                )
                #elseif os(macOS)
                try await PDFGenerationService.shared.shareInvoicePDF(
                    invoice: invoice,
                    businessProfile: businessProfile
                )
                #endif
                
                await MainActor.run {
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    isLoading = false
                    pdfExportErrorMessage = "Failed to export PDF: \(error.localizedDescription)"
                    showingPDFExportError = true
                }
            }
        }
    }
    
    private func deleteInvoice() {
        isLoading = true
        
        Task {
            await deleteFromDatabase()
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
    
    private func deleteFromDatabase() async {
        do {
            let invoiceId = invoice.id
            let descriptor = FetchDescriptor<InvoiceEntity>(
                predicate: #Predicate<InvoiceEntity> { entity in
                    entity.id == invoiceId
                }
            )
            
            let results = try modelContext.fetch(descriptor)
            if let entity = results.first {
                modelContext.delete(entity)
                try modelContext.save()
            }
        } catch {
            print("Failed to delete invoice: \(error)")
        }
    }
}

// MARK: - Supporting Views

private struct InvoiceItemDetailRow: View {
    let item: InvoiceItem
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .fontWeight(.medium)
                
                if !item.description.isEmpty && item.description != item.name {
                    Text(item.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
            
            Spacer()
            
            Text(formatDecimal(item.quantity))
                .font(.subheadline)
                .frame(width: 40, alignment: .trailing)
            
            Text(formatCurrency(item.rate))
                .font(.subheadline)
                .frame(width: 60, alignment: .trailing)
            
            Text(formatCurrency(item.total))
                .font(.subheadline)
                .fontWeight(.semibold)
                .frame(width: 80, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.clear)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    private func formatDecimal(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
}

private struct StatusBadge: View {
    let status: InvoiceStatus
    let isOverdue: Bool
    
    var body: some View {
        Text(displayStatus)
            .font(.caption)
            .fontWeight(.semibold)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }
    
    private var displayStatus: String {
        if isOverdue {
            return "OVERDUE"
        }
        return status.displayName.uppercased()
    }
    
    private var backgroundColor: Color {
        if isOverdue {
            return .red.opacity(0.2)
        }
        
        switch status {
        case .draft:
            return .gray.opacity(0.2)
        case .sent:
            return .blue.opacity(0.2)
        case .paid:
            return .green.opacity(0.2)
        case .overdue:
            return .red.opacity(0.2)
        case .cancelled:
            return .orange.opacity(0.2)
        }
    }
    
    private var foregroundColor: Color {
        if isOverdue {
            return .red
        }
        
        switch status {
        case .draft:
            return .gray
        case .sent:
            return .blue
        case .paid:
            return .green
        case .overdue:
            return .red
        case .cancelled:
            return .orange
        }
    }
}

#Preview {
    InvoiceDetailView(
        invoice: Invoice(
            invoiceNumber: "INV-001",
            date: Date(),
            dueDate: Calendar.current.date(byAdding: .day, value: 30, to: Date()) ?? Date(),
            client: Client(
                name: "John Doe",
                email: "john@example.com",
                company: "ACME Corp"
            ),
            items: [
                InvoiceItem(
                    name: "Website Design",
                    description: "Custom website design and development",
                    quantity: 1,
                    rate: 2500.00
                ),
                InvoiceItem(
                    name: "SEO Setup",
                    description: "Search engine optimization setup",
                    quantity: 1,
                    rate: 500.00
                )
            ]
        )
    )
    .modelContainer(SwiftDataStack.shared.modelContainer)
}