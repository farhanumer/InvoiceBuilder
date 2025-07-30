import SwiftUI
import SwiftData

public struct ItemsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var serviceItems: [ServiceItemEntity]
    
    @State private var searchText = ""
    @State private var showingAddItem = false
    @State private var selectedItem: ServiceItem?
    @State private var showingItemDetail = false
    @State private var sortOrder: SortOrder = .name
    @State private var isAscending = true
    @State private var selectedCategory: String = "All"
    
    private var filteredItems: [ServiceItem] {
        let items = serviceItems.map { ServiceItem(from: $0) }
        var filtered = items.filter { $0.isActive }
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.description?.localizedCaseInsensitiveContains(searchText) == true ||
                item.category?.localizedCaseInsensitiveContains(searchText) == true
            }
        }
        
        // Apply category filter
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Apply sorting
        return filtered.sorted { item1, item2 in
            let result: Bool
            switch sortOrder {
            case .name:
                result = item1.name.localizedCaseInsensitiveCompare(item2.name) == .orderedAscending
            case .category:
                let cat1 = item1.category ?? ""
                let cat2 = item2.category ?? ""
                result = cat1.localizedCaseInsensitiveCompare(cat2) == .orderedAscending
            case .rate:
                result = item1.defaultRate < item2.defaultRate
            case .dateAdded:
                result = item1.createdAt < item2.createdAt
            }
            return isAscending ? result : !result
        }
    }
    
    private var categories: [String] {
        let allCategories = serviceItems.compactMap { $0.category }.filter { !$0.isEmpty }
        let uniqueCategories = Array(Set(allCategories)).sorted()
        return ["All"] + uniqueCategories
    }
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if serviceItems.isEmpty && searchText.isEmpty {
                    emptyStateView
                } else {
                    itemListContent
                }
            }
            .navigationTitle("Service Items")
            .searchable(text: $searchText, prompt: "Search items...")
            .toolbar {
                #if os(iOS)
                ToolbarItem(placement: .topBarLeading) {
                    filtersMenu
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #else
                ToolbarItem(placement: .navigation) {
                    filtersMenu
                }
                
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddItem = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                #endif
            }
            .sheet(isPresented: $showingAddItem) {
                ItemDetailView()
            }
            .sheet(item: $selectedItem) { item in
                ItemDetailView(item: item)
            }
        }
    }
    
    // MARK: - Views
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 24) {
            Spacer()
            
            Image(systemName: "list.clipboard.fill")
                .font(.system(size: 64))
                .foregroundStyle(.blue)
            
            VStack(spacing: 8) {
                Text("No Service Items Yet")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text("Create reusable service items to quickly add to invoices")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Button {
                showingAddItem = true
            } label: {
                Label("Add First Item", systemImage: "plus")
            }
            .buttonStyle(.borderedProminent)
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var itemListContent: some View {
        if filteredItems.isEmpty && !searchText.isEmpty {
            noSearchResultsView
        } else {
            List {
                ForEach(filteredItems) { item in
                    ItemRowView(item: item) {
                        selectedItem = item
                    }
                }
                .onDelete(perform: deleteItems)
            }
            #if os(iOS)
            .listStyle(.insetGrouped)
            #else
            .listStyle(.sidebar)
            #endif
        }
    }
    
    @ViewBuilder
    private var noSearchResultsView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "magnifyingglass")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 4) {
                Text("No Results")
                    .font(.headline)
                
                Text("No items match \"\(searchText)\"")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
    }
    
    @ViewBuilder
    private var filtersMenu: some View {
        Menu {
            // Category Filter
            Menu("Category") {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Label(category, systemImage: selectedCategory == category ? "checkmark" : "")
                    }
                }
            }
            
            Divider()
            
            // Sort Options
            Menu("Sort by") {
                Button {
                    setSortOrder(.name)
                } label: {
                    Label("Name", systemImage: sortOrder == .name ? "checkmark" : "")
                }
                
                Button {
                    setSortOrder(.category)
                } label: {
                    Label("Category", systemImage: sortOrder == .category ? "checkmark" : "")
                }
                
                Button {
                    setSortOrder(.rate)
                } label: {
                    Label("Rate", systemImage: sortOrder == .rate ? "checkmark" : "")
                }
                
                Button {
                    setSortOrder(.dateAdded)
                } label: {
                    Label("Date Added", systemImage: sortOrder == .dateAdded ? "checkmark" : "")
                }
            }
            
            Divider()
            
            Button {
                isAscending.toggle()
            } label: {
                Label(
                    isAscending ? "Ascending" : "Descending",
                    systemImage: isAscending ? "arrow.up" : "arrow.down"
                )
            }
        } label: {
            Image(systemName: "line.3.horizontal.decrease.circle")
        }
    }
    
    // MARK: - Methods
    
    private func setSortOrder(_ order: SortOrder) {
        if sortOrder == order {
            isAscending.toggle()
        } else {
            sortOrder = order
            isAscending = true
        }
    }
    
    private func deleteItems(at offsets: IndexSet) {
        for index in offsets {
            let item = filteredItems[index]
            if let itemEntity = serviceItems.first(where: { $0.id == item.id }) {
                modelContext.delete(itemEntity)
            }
        }
        
        do {
            try modelContext.save()
        } catch {
            print("Failed to delete items: \(error)")
        }
    }
}

// MARK: - Supporting Types

private enum SortOrder {
    case name
    case category
    case rate
    case dateAdded
}

// MARK: - Item Row View

private struct ItemRowView: View {
    let item: ServiceItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                ItemIconView(
                    iconName: item.iconName,
                    category: item.category
                )
                
                // Item Info
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    if let category = item.category, !category.isEmpty {
                        Text(category)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(.blue.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Rate
                VStack(alignment: .trailing, spacing: 4) {
                    Text(formatCurrency(item.defaultRate))
                        .font(.headline)
                        .foregroundStyle(.primary)
                    
                    Text("per unit")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD" // TODO: Get from business profile
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

// MARK: - Item Icon View

private struct ItemIconView: View {
    let iconName: String?
    let category: String?
    
    private var displayIcon: String {
        if let iconName = iconName, !iconName.isEmpty {
            return iconName
        }
        
        // Default icons based on category
        guard let category = category?.lowercased() else {
            return "rectangle.3.group"
        }
        
        switch category {
        case "consulting", "consultation":
            return "person.2.fill"
        case "design", "creative":
            return "paintbrush.fill"
        case "development", "programming":
            return "laptopcomputer"
        case "marketing", "advertising":
            return "megaphone.fill"
        case "writing", "content":
            return "doc.text.fill"
        case "photography", "photo":
            return "camera.fill"
        case "legal", "law":
            return "scale.3d"
        case "accounting", "finance":
            return "dollarsign.circle.fill"
        default:
            return "rectangle.3.group"
        }
    }
    
    var body: some View {
        Image(systemName: displayIcon)
            .font(.title2)
            .foregroundStyle(.white)
            .frame(width: 44, height: 44)
            .background(iconColor)
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var iconColor: Color {
        guard let category = category?.lowercased() else {
            return .blue
        }
        
        switch category {
        case "consulting", "consultation":
            return .blue
        case "design", "creative":
            return .purple
        case "development", "programming":
            return .green
        case "marketing", "advertising":
            return .orange
        case "writing", "content":
            return .indigo
        case "photography", "photo":
            return .pink
        case "legal", "law":
            return .brown
        case "accounting", "finance":
            return .teal
        default:
            return .gray
        }
    }
}

#Preview {
    ItemsListView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}