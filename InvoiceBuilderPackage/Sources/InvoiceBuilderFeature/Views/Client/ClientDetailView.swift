import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
import PhotosUI
#elseif os(macOS)
import AppKit
#endif

public struct ClientDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var client: Client
    @State private var isEditing: Bool
    @State private var isLoading = false
    @State private var showingImagePicker = false
    @State private var showingDeleteConfirmation = false
    
    #if os(iOS)
    @State private var photosPickerItem: PhotosPickerItem?
    #endif
    
    // Form fields for address
    @State private var street = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = ""
    
    private let isNewClient: Bool
    
    public init() {
        let newClient = Client(
            name: "",
            email: ""
        )
        _client = State(initialValue: newClient)
        _isEditing = State(initialValue: true)
        isNewClient = true
    }
    
    public init(client: Client) {
        _client = State(initialValue: client)
        _isEditing = State(initialValue: false)
        isNewClient = false
    }
    
    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 20) {
                    avatarSection
                    basicInfoSection
                    contactSection
                    addressSection
                    notesSection
                    
                    if !isNewClient && !isEditing {
                        deleteSection
                    }
                }
                .padding()
                .frame(maxWidth: 600) // Reasonable form width on macOS
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(isNewClient ? "New Client" : (isEditing ? "Edit Client" : client.name))
            #if os(iOS)
            .navigationBarTitleDisplayMode(isNewClient ? .inline : .large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(isNewClient ? "Cancel" : "Done") {
                        if isNewClient || !isEditing {
                            dismiss()
                        } else {
                            isEditing = false
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveClient()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                    } else if !isNewClient {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .onAppear {
                populateAddressFields()
            }
            .overlay {
                if isLoading {
                    LoadingOverlay()
                }
            }
            .confirmationDialog(
                "Delete Client",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible,
                presenting: client
            ) { client in
                Button("Delete Client", role: .destructive) {
                    deleteClient()
                }
                Button("Cancel", role: .cancel) { }
            } message: { client in
                Text("Are you sure you want to delete \(client.name)? This action cannot be undone.")
            }
            #if os(iOS)
            .onChange(of: photosPickerItem) { _, newItem in
                loadImage(from: newItem)
            }
            #endif
        }
    }
    
    // MARK: - Form Sections
    
    @ViewBuilder
    private var avatarSection: some View {
        CardSection(title: "Profile Photo") {
            HStack {
                Spacer()
                
                VStack(spacing: 12) {
                    ClientAvatarView(
                        avatarData: client.avatarData,
                        name: client.name.isEmpty ? "Client" : client.name,
                        size: 80
                    )
                    
                    if isEditing {
                        HStack(spacing: 12) {
                            #if os(iOS)
                            PhotosPicker(
                                selection: $photosPickerItem,
                                matching: .images,
                                photoLibrary: .shared()
                            ) {
                                Text("Change Photo")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                            }
                            #else
                            Button("Change Photo") {
                                showMacOSFilePicker()
                            }
                            .font(.caption)
                            .foregroundStyle(.blue)
                            #endif
                            
                            if client.avatarData != nil {
                                Button("Remove Photo") {
                                    client.avatarData = nil
                                }
                                .font(.caption)
                                .foregroundStyle(.red)
                            }
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, 8)
        }
    }
    
    @ViewBuilder
    private var basicInfoSection: some View {
        CardSection(title: "Client Information") {
            ClientFormField(
                title: "Full Name",
                text: $client.name,
                placeholder: "John Doe",
                isRequired: true,
                isEditing: isEditing
            )
            
            ClientFormField(
                title: "Company",
                text: Binding(
                    get: { client.company ?? "" },
                    set: { client.company = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "Acme Corporation",
                isEditing: isEditing
            )
        }
    }
    
    @ViewBuilder
    private var contactSection: some View {
        CardSection(title: "Contact Information") {
            ClientFormField(
                title: "Email Address",
                text: $client.email,
                placeholder: "john@example.com",
                isRequired: true,
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            #endif
            
            ClientFormField(
                title: "Phone Number",
                text: Binding(
                    get: { client.phone ?? "" },
                    set: { client.phone = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "+1 (555) 123-4567",
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.phonePad)
            #endif
            
            ClientFormField(
                title: "Website",
                text: Binding(
                    get: { client.website ?? "" },
                    set: { client.website = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "https://www.example.com",
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            #endif
            
            ClientFormField(
                title: "Tax Number",
                text: Binding(
                    get: { client.taxNumber ?? "" },
                    set: { client.taxNumber = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "Tax ID or VAT number",
                isEditing: isEditing
            )
        }
    }
    
    @ViewBuilder
    private var addressSection: some View {
        CardSection(title: "Address") {
            ClientFormField(
                title: "Street Address",
                text: $street,
                placeholder: "123 Main Street",
                isEditing: isEditing
            )
            
            HStack(spacing: 12) {
                ClientFormField(
                    title: "City",
                    text: $city,
                    placeholder: "New York",
                    isEditing: isEditing
                )
                
                ClientFormField(
                    title: "State",
                    text: $state,
                    placeholder: "NY",
                    isEditing: isEditing
                )
            }
            
            HStack(spacing: 12) {
                ClientFormField(
                    title: "Postal Code",
                    text: $postalCode,
                    placeholder: "10001",
                    isEditing: isEditing
                )
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                
                ClientFormField(
                    title: "Country",
                    text: $country,
                    placeholder: "United States",
                    isEditing: isEditing
                )
            }
        }
    }
    
    @ViewBuilder
    private var notesSection: some View {
        CardSection(title: "Notes") {
            if isEditing {
                TextField("Additional notes about this client", text: Binding(
                    get: { client.notes ?? "" },
                    set: { client.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            } else if let notes = client.notes, !notes.isEmpty {
                Text(notes)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    @ViewBuilder
    private var deleteSection: some View {
        CardSection(title: "Actions") {
            Button("Delete Client", role: .destructive) {
                showingDeleteConfirmation = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !client.name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !client.email.isEmpty &&
        isValidEmail(client.email)
    }
    
    // MARK: - Methods
    
    private func populateAddressFields() {
        if let address = client.address {
            street = address.street
            city = address.city
            state = address.state
            postalCode = address.postalCode
            country = address.country
        }
    }
    
    private func saveClient() {
        isLoading = true
        
        Task {
            // Update address if any field is filled
            if !street.isEmpty || !city.isEmpty || !state.isEmpty || !postalCode.isEmpty || !country.isEmpty {
                client.address = Address(
                    street: street,
                    city: city,
                    state: state,
                    postalCode: postalCode,
                    country: country
                )
            } else {
                client.address = nil
            }
            
            // Update timestamps
            client.updatedAt = Date()
            if isNewClient {
                client.createdDate = Date()
            }
            
            // Save to database
            await saveToDatabase()
            
            await MainActor.run {
                isLoading = false
                
                if isNewClient {
                    dismiss()
                } else {
                    isEditing = false
                }
            }
        }
    }
    
    private func deleteClient() {
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
        if isNewClient {
            // Create new client entity
            let clientEntity = ClientEntity(
                name: client.name,
                email: client.email
            )
            
            updateClientEntity(clientEntity, with: client)
            modelContext.insert(clientEntity)
        } else {
            // Update existing client entity
            let clientId = client.id
            let descriptor = FetchDescriptor<ClientEntity>(
                predicate: #Predicate<ClientEntity> { $0.id == clientId }
            )
            
            do {
                let existingClients = try modelContext.fetch(descriptor)
                if let existingClient = existingClients.first {
                    updateClientEntity(existingClient, with: client)
                }
            } catch {
                print("Failed to fetch client for update: \(error)")
            }
        }
        
        do {
            try modelContext.save()
            print("Client saved successfully")
        } catch {
            print("Failed to save client: \(error)")
        }
    }
    
    private func deleteFromDatabase() async {
        let clientId = client.id
        let descriptor = FetchDescriptor<ClientEntity>(
            predicate: #Predicate<ClientEntity> { $0.id == clientId }
        )
        
        do {
            let clientsToDelete = try modelContext.fetch(descriptor)
            for clientEntity in clientsToDelete {
                modelContext.delete(clientEntity)
            }
            try modelContext.save()
            print("Client deleted successfully")
        } catch {
            print("Failed to delete client: \(error)")
        }
    }
    
    private func updateClientEntity(_ entity: ClientEntity, with client: Client) {
        entity.name = client.name
        entity.email = client.email
        entity.phone = client.phone
        entity.company = client.company
        entity.website = client.website
        entity.taxNumber = client.taxNumber
        entity.avatarData = client.avatarData
        entity.notes = client.notes
        entity.updatedAt = client.updatedAt
        
        // Handle address
        if let address = client.address {
            if let existingAddress = entity.address {
                existingAddress.street = address.street
                existingAddress.city = address.city
                existingAddress.state = address.state
                existingAddress.postalCode = address.postalCode
                existingAddress.country = address.country
            } else {
                let newAddress = AddressEntity(
                    street: address.street,
                    city: address.city,
                    state: address.state,
                    postalCode: address.postalCode,
                    country: address.country
                )
                entity.address = newAddress
                modelContext.insert(newAddress)
            }
        } else {
            if let existingAddress = entity.address {
                modelContext.delete(existingAddress)
                entity.address = nil
            }
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    // MARK: - Photo Handling Methods
    
    #if os(iOS)
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        client.avatarData = data
                    }
                }
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
    #endif
    
    #if os(macOS)
    private func showMacOSFilePicker() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            do {
                let data = try Data(contentsOf: url)
                client.avatarData = data
            } catch {
                print("Failed to load image: \(error)")
            }
        }
    }
    #endif
}

// MARK: - Supporting Views

private struct ClientFormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var isRequired: Bool = false
    let isEditing: Bool
    
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
                
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
            }
        } else if !text.isEmpty {
            HStack {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(text)
            }
        }
    }
}

// MARK: - Client Avatar View (Reused from ClientListView)

private struct ClientAvatarView: View {
    let avatarData: Data?
    let name: String
    let size: CGFloat
    
    var body: some View {
        Group {
            if let avatarData = avatarData, let image = loadImage(from: avatarData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } else {
                // Fallback to initials
                Text(nameInitials)
                    .font(.system(size: size * 0.4, weight: .medium))
                    .foregroundStyle(.white)
                    .background(
                        Circle()
                            .fill(avatarColor)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
    }
    
    private var nameInitials: String {
        let components = name.components(separatedBy: .whitespaces)
        let initials = components.compactMap { $0.first?.uppercased() }
        return String(initials.prefix(2).joined())
    }
    
    private var avatarColor: Color {
        let colors: [Color] = [.blue, .green, .orange, .purple, .pink, .indigo, .teal, .cyan]
        let hash = abs(name.hashValue)
        return colors[hash % colors.count]
    }
    
    private func loadImage(from data: Data) -> Image? {
        #if os(iOS)
        if let uiImage = UIKit.UIImage(data: data) {
            return Image(uiImage: uiImage)
        }
        #elseif os(macOS)
        if let nsImage = AppKit.NSImage(data: data) {
            return Image(nsImage: nsImage)
        }
        #endif
        return nil
    }
}

// MARK: - Card Section Helper

private struct CardSection<Content: View>: View {
    let title: String
    let content: Content
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
            
            VStack(spacing: 12) {
                content
            }
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ClientDetailView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}