import SwiftUI
import SwiftData
import Charts

@MainActor
public struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    
    @Query private var invoices: [InvoiceEntity]
    @Query private var clients: [ClientEntity]
    @Query private var businessProfiles: [BusinessProfileEntity]
    
    @State private var selectedTimeframe: TimeFrame = .thisMonth
    @State private var isLoading = false
    
    private var businessProfile: BusinessProfile? {
        businessProfiles.first.map { BusinessProfile(from: $0) }
    }
    
    private var filteredInvoices: [Invoice] {
        let allInvoices = invoices.map { Invoice(from: $0) }
        let calendar = Calendar.current
        let now = Date()
        
        var result: [Invoice] = []
        for invoice in allInvoices {
            let matches: Bool
            switch selectedTimeframe {
            case .thisWeek:
                matches = calendar.isDate(invoice.date, equalTo: now, toGranularity: .weekOfYear)
            case .thisMonth:
                matches = calendar.isDate(invoice.date, equalTo: now, toGranularity: .month)
            case .thisQuarter:
                let quarterStart = calendar.dateInterval(of: .quarter, for: now)?.start ?? now
                let quarterEnd = calendar.dateInterval(of: .quarter, for: now)?.end ?? now
                matches = invoice.date >= quarterStart && invoice.date <= quarterEnd
            case .thisYear:
                matches = calendar.isDate(invoice.date, equalTo: now, toGranularity: .year)
            case .allTime:
                matches = true
            }
            
            if matches {
                result.append(invoice)
            }
        }
        return result
    }
    
    private var analytics: DashboardAnalytics {
        DashboardAnalytics(invoices: filteredInvoices, clients: clients.map { Client(from: $0) })
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    // Header with business info
                    if let businessProfile = businessProfile {
                        businessHeaderSection(businessProfile)
                    }
                    
                    // Time frame selector
                    timeFrameSelector
                    
                    // Key metrics
                    keyMetricsSection
                    
                    // Revenue chart
                    revenueChartSection
                    
                    // Invoice status breakdown
                    invoiceStatusSection
                    
                    // Top clients
                    topClientsSection
                    
                    // Recent activity
                    recentActivitySection
                }
                .padding()
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle("Dashboard")
            .refreshable {
                // Refresh data
                try? await Task.sleep(for: .seconds(1))
            }
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private func businessHeaderSection(_ profile: BusinessProfile) -> some View {
        HStack {
            // Business logo
            if let logoData = profile.logo,
               let logoImage = loadImage(from: logoData) {
                logoImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 50, height: 50)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.businessName)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("Dashboard Overview")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var timeFrameSelector: some View {
        Picker("Time Frame", selection: $selectedTimeframe) {
            ForEach(TimeFrame.allCases, id: \.self) { timeFrame in
                Text(timeFrame.displayName)
                    .tag(timeFrame)
            }
        }
        .pickerStyle(.segmented)
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var keyMetricsSection: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
            MetricCard(
                title: "Total Revenue",
                value: formatCurrency(analytics.totalRevenue),
                icon: "dollarsign.circle.fill",
                color: .green,
                trend: analytics.revenueTrend
            )
            
            MetricCard(
                title: "Outstanding",
                value: formatCurrency(analytics.outstandingAmount),
                icon: "clock.circle.fill",
                color: .orange,
                trend: nil
            )
            
            MetricCard(
                title: "Total Invoices",
                value: "\(analytics.totalInvoices)",
                icon: "doc.text.fill",
                color: .blue,
                trend: analytics.invoiceCountTrend
            )
            
            MetricCard(
                title: "Active Clients",
                value: "\(analytics.activeClients)",
                icon: "person.2.fill",
                color: .purple,
                trend: nil
            )
        }
    }
    
    @ViewBuilder
    private var revenueChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Revenue Over Time")
                .font(.headline)
                .fontWeight(.semibold)
            
            if analytics.revenueData.isEmpty {
                Text("No revenue data available")
                    .foregroundStyle(.secondary)
                    .frame(height: 200)
                    .frame(maxWidth: .infinity)
            } else {
                Chart(analytics.revenueData) { dataPoint in
                    BarMark(
                        x: .value("Period", dataPoint.period),
                        y: .value("Revenue", dataPoint.amount)
                    )
                    .foregroundStyle(.blue.gradient)
                }
                .frame(height: 200)
                .chartYScale(domain: 0...Double(truncating: (analytics.revenueData.map(\.amount).max() ?? 1000) as NSDecimalNumber))
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var invoiceStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Invoice Status Breakdown")
                .font(.headline)
                .fontWeight(.semibold)
            
            if analytics.statusBreakdown.isEmpty {
                Text("No invoices found")
                    .foregroundStyle(.secondary)
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 12) {
                    ForEach(analytics.statusBreakdown, id: \.status) { breakdown in
                        StatusBreakdownCard(breakdown: breakdown)
                    }
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var topClientsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Top Clients")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("by Revenue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if analytics.topClients.isEmpty {
                Text("No client data available")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(analytics.topClients.prefix(5), id: \.client.id) { clientRevenue in
                    TopClientRow(clientRevenue: clientRevenue)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    @ViewBuilder
    private var recentActivitySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Activity")
                .font(.headline)
                .fontWeight(.semibold)
            
            if analytics.recentInvoices.isEmpty {
                Text("No recent activity")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(analytics.recentInvoices.prefix(5)) { invoice in
                    RecentActivityRow(invoice: invoice)
                }
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
    
    // MARK: - Helper Methods
    
    private func loadImage(from data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = businessProfile?.currency.rawValue ?? "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Supporting Types

private enum TimeFrame: String, CaseIterable {
    case thisWeek = "week"
    case thisMonth = "month"
    case thisQuarter = "quarter"
    case thisYear = "year"
    case allTime = "all"
    
    var displayName: String {
        switch self {
        case .thisWeek: return "This Week"
        case .thisMonth: return "This Month"
        case .thisQuarter: return "This Quarter"
        case .thisYear: return "This Year"
        case .allTime: return "All Time"
        }
    }
}

private struct DashboardAnalytics {
    let invoices: [Invoice]
    let clients: [Client]
    
    var totalRevenue: Decimal {
        invoices
            .filter { $0.status == .paid }
            .reduce(0) { $0 + $1.total }
    }
    
    var outstandingAmount: Decimal {
        invoices
            .filter { $0.status == .sent || $0.status == .overdue }
            .reduce(0) { $0 + $1.total }
    }
    
    var totalInvoices: Int {
        invoices.count
    }
    
    var activeClients: Int {
        Set(invoices.map { $0.client.id }).count
    }
    
    var revenueTrend: TrendDirection? {
        // Calculate trend based on previous period comparison
        // This is a simplified implementation
        if totalRevenue > 0 {
            return .up
        } else if totalRevenue < 0 {
            return .down
        }
        return nil
    }
    
    var invoiceCountTrend: TrendDirection? {
        // Simplified trend calculation
        if totalInvoices > 0 {
            return .up
        }
        return nil
    }
    
    var revenueData: [RevenueDataPoint] {
        let calendar = Calendar.current
        let grouped = Dictionary(grouping: invoices.filter { $0.status == .paid }) { invoice in
            calendar.dateInterval(of: .weekOfYear, for: invoice.date)?.start ?? invoice.date
        }
        
        return grouped.map { date, invoices in
            RevenueDataPoint(
                period: date,
                amount: invoices.reduce(0) { $0 + $1.total }
            )
        }.sorted { $0.period < $1.period }
    }
    
    var statusBreakdown: [StatusBreakdown] {
        let grouped = Dictionary(grouping: invoices) { $0.status }
        return grouped.map { status, invoices in
            StatusBreakdown(
                status: status,
                count: invoices.count,
                totalAmount: invoices.reduce(0) { $0 + $1.total }
            )
        }.sorted { $0.count > $1.count }
    }
    
    var topClients: [ClientRevenue] {
        let grouped = Dictionary(grouping: invoices) { $0.client.id }
        var clientRevenues: [ClientRevenue] = []
        
        for (clientId, clientInvoices) in grouped {
            if let client = clients.first(where: { $0.id == clientId }) {
                let totalRevenue = clientInvoices
                    .filter { $0.status == .paid }
                    .reduce(0) { $0 + $1.total }
                
                clientRevenues.append(ClientRevenue(
                    client: client,
                    totalRevenue: totalRevenue,
                    invoiceCount: clientInvoices.count
                ))
            }
        }
        
        return clientRevenues.sorted { $0.totalRevenue > $1.totalRevenue }
    }
    
    var recentInvoices: [Invoice] {
        invoices
            .sorted { $0.createdAt > $1.createdAt }
            .prefix(10)
            .map { $0 }
    }
}

private struct RevenueDataPoint: Identifiable {
    let id = UUID()
    let period: Date
    let amount: Decimal
}

private struct StatusBreakdown {
    let status: InvoiceStatus
    let count: Int
    let totalAmount: Decimal
}

private struct ClientRevenue {
    let client: Client
    let totalRevenue: Decimal
    let invoiceCount: Int
}

private enum TrendDirection {
    case up
    case down
    case flat
}

// MARK: - Supporting Views

private struct MetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    let trend: TrendDirection?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                
                Spacer()
                
                if let trend = trend {
                    Image(systemName: trendIcon(trend))
                        .font(.caption)
                        .foregroundStyle(trendColor(trend))
                }
            }
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private func trendIcon(_ trend: TrendDirection) -> String {
        switch trend {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
    
    private func trendColor(_ trend: TrendDirection) -> Color {
        switch trend {
        case .up: return .green
        case .down: return .red
        case .flat: return .gray
        }
    }
}

private struct StatusBreakdownCard: View {
    let breakdown: StatusBreakdown
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Circle()
                    .fill(statusColor)
                    .frame(width: 8, height: 8)
                
                Text(breakdown.status.displayName)
                    .font(.caption)
                    .fontWeight(.medium)
                
                Spacer()
            }
            
            Text("\(breakdown.count)")
                .font(.headline)
                .fontWeight(.bold)
            
            Text(formatCurrency(breakdown.totalAmount))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
    }
    
    private var statusColor: Color {
        switch breakdown.status {
        case .draft: return .gray
        case .sent: return .blue
        case .paid: return .green
        case .overdue: return .red
        case .cancelled: return .orange
        }
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

private struct TopClientRow: View {
    let clientRevenue: ClientRevenue
    
    var body: some View {
        HStack(spacing: 12) {
            // Client initial or avatar
            Circle()
                .fill(.blue.opacity(0.2))
                .frame(width: 32, height: 32)
                .overlay {
                    Text(String(clientRevenue.client.name.prefix(1)))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundStyle(.blue)
                }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(clientRevenue.client.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text("\(clientRevenue.invoiceCount) invoice\(clientRevenue.invoiceCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text(formatCurrency(clientRevenue.totalRevenue))
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

private struct RecentActivityRow: View {
    let invoice: Invoice
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "doc.text")
                .font(.title3)
                .foregroundStyle(.blue)
                .frame(width: 24)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(invoice.invoiceNumber)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(invoice.client.name)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(formatCurrency(invoice.total))
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Text(invoice.createdAt, style: .date)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

#Preview {
    DashboardView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}