import SwiftUI

public struct ServiceItemPickerView: View {
    @Environment(\.dismiss) private var dismiss
    
    let serviceItems: [ServiceItem]
    let onItemSelected: (ServiceItem) -> Void
    
    @State private var searchText = ""
    @State private var selectedCategory: String = "All"
    
    private var categories: [String] {
        let itemCategories = serviceItems.compactMap { $0.category }.filter { !$0.isEmpty }
        let uniqueCategories = Array(Set(itemCategories)).sorted()
        return ["All"] + uniqueCategories
    }
    
    private var filteredItems: [ServiceItem] {
        var filtered = serviceItems
            .filter { $0.isActive }
            .sorted { $0.name < $1.name }
        
        // Filter by category
        if selectedCategory != "All" {
            filtered = filtered.filter { $0.category == selectedCategory }
        }
        
        // Filter by search text
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.name.localizedCaseInsensitiveContains(searchText) ||
                (item.description?.localizedCaseInsensitiveContains(searchText) ?? false) ||
                (item.category?.localizedCaseInsensitiveContains(searchText) ?? false)
            }
        }
        
        return filtered
    }
    
    public init(serviceItems: [ServiceItem], onItemSelected: @escaping (ServiceItem) -> Void) {
        self.serviceItems = serviceItems
        self.onItemSelected = onItemSelected
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Search and Filter Section
                VStack(spacing: 12) {
                    SearchBar(text: $searchText)
                    
                    if categories.count > 1 {
                        CategoryPicker(
                            categories: categories,
                            selectedCategory: $selectedCategory
                        )
                    }
                }
                .padding()
                .background(.regularMaterial)
                
                // Service Items List
                if filteredItems.isEmpty {
                    emptyStateView
                } else {
                    List(filteredItems) { item in
                        ServiceItemPickerRow(item: item) {
                            onItemSelected(item)
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Add Service Item")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
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
    
    @ViewBuilder
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "list.clipboard")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            
            Text("No Service Items Found")
                .font(.title2)
                .fontWeight(.semibold)
            
            if searchText.isEmpty {
                if selectedCategory == "All" {
                    Text("You haven't added any service items yet.\nAdd your first service item to get started.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("No items found in the \"\(selectedCategory)\" category.\nTry selecting a different category.")
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
            } else {
                Text("No items match your search.\nTry a different search term or category.")
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct ServiceItemPickerRow: View {
    let item: ServiceItem
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Icon
                if let iconName = item.iconName, !iconName.isEmpty {
                    Image(systemName: iconName)
                        .font(.title2)
                        .foregroundStyle(.blue)
                        .frame(width: 36, height: 36)
                        .background(.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    Image(systemName: "rectangle.3.group")
                        .font(.title2)
                        .foregroundStyle(.gray)
                        .frame(width: 36, height: 36)
                        .background(.gray.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                
                // Item Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(item.name)
                            .font(.headline)
                            .fontWeight(.medium)
                            .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Text(formatCurrency(item.defaultRate))
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundStyle(.blue)
                    }
                    
                    if let description = item.description, !description.isEmpty {
                        Text(description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                    }
                    
                    HStack {
                        if let category = item.category, !category.isEmpty {
                            Text(category)
                                .font(.caption)
                                .fontWeight(.medium)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.green.opacity(0.1))
                                .foregroundStyle(.green)
                                .clipShape(Capsule())
                        }
                        
                        Spacer()
                        
                        Text("Tap to add")
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func formatCurrency(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
}

private struct CategoryPicker: View {
    let categories: [String]
    @Binding var selectedCategory: String
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(categories, id: \.self) { category in
                    Button {
                        selectedCategory = category
                    } label: {
                        Text(category)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(
                                selectedCategory == category ?
                                Color.blue : Color.gray.opacity(0.2)
                            )
                            .foregroundStyle(
                                selectedCategory == category ?
                                .white : .primary
                            )
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

private struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)
            
            TextField("Search service items", text: $text)
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

#Preview {
    ServiceItemPickerView(serviceItems: [
        ServiceItem(
            name: "Website Design",
            description: "Custom website design and development",
            defaultRate: 75.00,
            category: "Design",
            iconName: "laptopcomputer"
        ),
        ServiceItem(
            name: "SEO Consultation",
            description: "Search engine optimization analysis and recommendations",
            defaultRate: 125.00,
            category: "Marketing",
            iconName: "magnifyingglass"
        ),
        ServiceItem(
            name: "Content Writing",
            description: "Professional content creation services",
            defaultRate: 50.00,
            category: "Writing",
            iconName: "doc.text"
        )
    ]) { item in
        print("Selected: \(item.name)")
    }
}