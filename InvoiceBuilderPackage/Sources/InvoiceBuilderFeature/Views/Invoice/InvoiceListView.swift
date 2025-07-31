import SwiftUI
import SwiftData

public struct InvoiceListView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var invoices: [InvoiceEntity]
    @Query private var businessProfiles: [BusinessProfileEntity]
    @State private var searchText = ""
    @State private var selectedStatus: InvoiceStatusFilter = .all
    @State private var showingNewInvoice = false
    @State private var selectedInvoice: Invoice?
    @State private var showingInvoiceDetail = false
    
    private var filteredInvoices: [Invoice] {
        let allInvoices = invoices.map { Invoice(from: $0) }
        
        var filtered = allInvoices
        
        // Filter by status
        switch selectedStatus {
        case .all:
            break
        case .draft:
            filtered = filtered.filter { $0.status == .draft }
        case .sent:
            filtered = filtered.filter { $0.status == .sent }
        case .paid:
            filtered = filtered.filter { $0.status == .paid }
        case .overdue:
            filtered = filtered.filter { $0.isOverdue }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { invoice in
                invoice.invoiceNumber.localizedCaseInsensitiveContains(searchText) ||
                invoice.client.name.localizedCaseInsensitiveContains(searchText) ||
                (invoice.client.company?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (invoice.notes?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (invoice.poNumber?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        // Sort by issue date (newest first)
        return filtered.sorted { $0.date > $1.date }
    }
    
    private var summaryStats: InvoiceSummaryStats {
        let allInvoices = invoices.map { Invoice(from: $0) }
        let businessProfile = businessProfiles.first.map { BusinessProfile(from: $0) }
        return InvoiceSummaryStats(invoices: allInvoices, businessProfile: businessProfile)
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Summary Stats Card
                if !invoices.isEmpty {
                    SummaryStatsCard(stats: summaryStats)
                        .padding()
                        .background(.regularMaterial)
                }
                
                // Search and Filter Section
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    StatusFilterSegmentedControl(selectedStatus: $selectedStatus)
                }
                .padding()
                .background(.regularMaterial)
                
                // Invoice List
                if filteredInvoices.isEmpty {
                    emptyStateView
                } else {
                    List(filteredInvoices) { invoice in
                        InvoiceListRow(invoice: invoice) {
                            selectedInvoice = invoice
                            showingInvoiceDetail = true
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Invoices")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingNewInvoice = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
        .sheet(isPresented: $showingNewInvoice) {
            InvoiceBuilderView { invoice in
                // Handle saved invoice
                showingNewInvoice = false
            }
        }
        .sheet(isPresented: $showingInvoiceDetail) {
            if let selectedInvoice = selectedInvoice {
                InvoiceDetailView(invoice: selectedInvoice)
            }
        }
    }
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "doc.text")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            VStack(spacing: 8) {
                Text(emptyStateTitle)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(emptyStateMessage)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            if invoices.isEmpty {
                Button {
                    showingNewInvoice = true
                } label: {
                    Label("Create First Invoice", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var emptyStateTitle: String {
        if invoices.isEmpty {
            return "No Invoices Yet"
        } else if searchText.isEmpty {
            return "No \(selectedStatus.displayName) Invoices"
        } else {
            return "No Invoices Found"
        }
    }
    
    private var emptyStateMessage: String {
        if invoices.isEmpty {
            return "Create your first invoice to get started with billing your clients."
        } else if searchText.isEmpty {
            return "You don't have any \(selectedStatus.displayName.lowercased()) invoices at the moment."
        } else {
            return "No invoices match your search criteria. Try adjusting your search terms or filters."
        }
    }
}

// MARK: - Supporting Views

private struct SummaryStatsCard: View {
    let stats: InvoiceSummaryStats
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Invoice Summary")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatItem(
                    title: "Total Value",
                    value: stats.formattedTotalValue,
                    color: .blue,
                    icon: "dollarsign.circle"
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    title: "Outstanding",
                    value: stats.formattedOutstanding,
                    color: .orange,
                    icon: "clock.circle"
                )
                
                Divider()
                    .frame(height: 30)
                
                StatItem(
                    title: "Overdue",
                    value: "\(stats.overdueCount)",
                    color: .red,
                    icon: "exclamationmark.circle"
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    let color: Color
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
                
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct InvoiceListRow: View {
    let invoice: Invoice
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 8) {
                // Main Row
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        // Invoice Number and Status
                        HStack(spacing: 8) {
                            Text(invoice.invoiceNumber)
                                .font(.headline)
                                .fontWeight(.semibold)
                            
                            StatusBadge(status: invoice.status, isOverdue: invoice.isOverdue)
                        }
                        
                        // Client Name
                        Text(invoice.client.name)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        
                        // Date Info
                        HStack(spacing: 16) {
                            Label(
                                invoice.date.formatted(date: .abbreviated, time: .omitted),
                                systemImage: "calendar"
                            )
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            
                            if invoice.isOverdue {
                                Label(
                                    "\(invoice.daysPastDue) days overdue",
                                    systemImage: "clock.badge.exclamationmark"
                                )
                                .font(.caption)
                                .foregroundStyle(.red)
                            } else {
                                Label(
                                    "Due \(invoice.dueDate.formatted(date: .abbreviated, time: .omitted))",
                                    systemImage: "calendar.badge.clock"
                                )
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Amount and Arrow
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(invoice.formattedTotal)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.primary)
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
                
                // Additional Info (if PO Number exists)
                if let poNumber = invoice.poNumber, !poNumber.isEmpty {
                    HStack {
                        Text("PO: \(poNumber)")
                            .font(.caption)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .foregroundStyle(.blue)
                            .clipShape(Capsule())
                        
                        Spacer()
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

private struct StatusBadge: View {
    let status: InvoiceStatus
    let isOverdue: Bool
    
    var body: some View {
        Text(displayStatus)
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(backgroundColor)
            .foregroundStyle(foregroundColor)
            .clipShape(Capsule())
    }
    
    private var displayStatus: String {
        if isOverdue {
            return "Overdue"
        }
        return status.displayName
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

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search invoices", text: $text)
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

private struct StatusFilterSegmentedControl: View {
    @Binding var selectedStatus: InvoiceStatusFilter
    
    var body: some View {
        Picker("Status Filter", selection: $selectedStatus) {
            ForEach(InvoiceStatusFilter.allCases, id: \.self) { status in
                Text(status.displayName)
                    .tag(status)
            }
        }
        .pickerStyle(.segmented)
    }
}

// MARK: - Supporting Types

private enum InvoiceStatusFilter: CaseIterable {
    case all
    case draft
    case sent
    case paid
    case overdue
    
    var displayName: String {
        switch self {
        case .all: return "All"
        case .draft: return "Draft"
        case .sent: return "Sent"
        case .paid: return "Paid"
        case .overdue: return "Overdue"
        }
    }
}

private struct InvoiceSummaryStats {
    let totalValue: Decimal
    let outstanding: Decimal
    let overdueCount: Int
    private let businessProfile: BusinessProfile?
    
    init(invoices: [Invoice], businessProfile: BusinessProfile? = nil) {
        self.totalValue = invoices.reduce(into: 0) { $0 += $1.total }
        self.outstanding = invoices
            .filter { $0.status == .sent || $0.status == .overdue || $0.isOverdue }
            .reduce(into: 0) { $0 += $1.total }
        self.overdueCount = invoices.filter { $0.isOverdue }.count
        self.businessProfile = businessProfile
    }
    
    var formattedTotalValue: String {
        formatCurrency(totalValue)
    }
    
    var formattedOutstanding: String {
        formatCurrency(outstanding)
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
    InvoiceListView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}