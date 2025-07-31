import SwiftUI
import SwiftData

#if os(iOS)
import UIKit
#endif

public struct BusinessProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @Query private var businessProfiles: [BusinessProfileEntity]
    @State private var businessProfile: BusinessProfile
    @State private var isEditing = false
    @State private var showingImagePicker = false
    @State private var showingSignatureCapture = false
    @State private var isLoading = false
    @State private var showingDeleteConfirmation = false
    
    // Form fields
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var postalCode = ""
    @State private var country = ""
    @State private var industry = ""
    @State private var businessDescription = ""
    @State private var taxIdString = ""
    @State private var registrationNumberString = ""
    @State private var defaultTaxRateString = ""
    @State private var invoiceNumberPrefixString = ""
    @State private var nextInvoiceNumberString = ""
    @State private var selectedInvoiceNumberFormat: InvoiceNumberFormat = .sequential
    @State private var includeYearInInvoiceNumber = false
    @State private var includeMonthInInvoiceNumber = false
    @State private var invoiceNumberPadding = 4
    
    public init() {
        // Initialize with existing profile or create new one
        let existingProfile = BusinessProfile(
            businessName: "",
            ownerName: "",
            email: ""
        )
        _businessProfile = State(initialValue: existingProfile)
        _isEditing = State(initialValue: true)
    }
    
    public init(businessProfile: BusinessProfile) {
        _businessProfile = State(initialValue: businessProfile)
        _isEditing = State(initialValue: false)
    }
    
    public var body: some View {
        NavigationStack {
            Form {
                basicInfoSection
                contactSection
                businessDetailsSection
                brandingSection
                invoiceSettingsSection
                taxAndPaymentSection
            }
            .navigationTitle(isEditing ? "Edit Business Profile" : "Business Profile")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if isEditing {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
                
                ToolbarItem(placement: .primaryAction) {
                    if isEditing {
                        Button("Save") {
                            saveBusinessProfile()
                        }
                        .fontWeight(.semibold)
                        .disabled(!isFormValid)
                    } else {
                        Button("Edit") {
                            isEditing = true
                        }
                    }
                }
            }
            .onAppear {
                loadExistingProfile()
                populateFormFields()
            }
            .overlay {
                if isLoading {
                    LoadingOverlay()
                }
            }
        }
    }
    
    // MARK: - Form Sections
    
    @ViewBuilder
    private var basicInfoSection: some View {
        Section("Business Information") {
            FormTextField(
                title: "Business Name",
                text: $businessProfile.businessName,
                placeholder: "Acme Corporation",
                isRequired: true,
                isEditing: isEditing
            )
            
            FormTextField(
                title: "Owner Name",
                text: $businessProfile.ownerName,
                placeholder: "John Doe",
                isRequired: true,
                isEditing: isEditing
            )
            
            FormTextField(
                title: "Industry",
                text: $industry,
                placeholder: "Consulting, Design, etc.",
                isEditing: isEditing
            )
            
            if isEditing {
                TextField("Business Description", text: $businessDescription, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            } else if !businessDescription.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Business Description")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(businessDescription)
                }
            }
        }
    }
    
    @ViewBuilder
    private var contactSection: some View {
        Section("Contact Information") {
            FormTextField(
                title: "Email Address",
                text: $businessProfile.email,
                placeholder: "business@example.com",
                isRequired: true,
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.emailAddress)
            .textInputAutocapitalization(.never)
            #endif
            
            FormTextField(
                title: "Phone Number",
                text: Binding(
                    get: { businessProfile.phone ?? "" },
                    set: { businessProfile.phone = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "+1 (555) 123-4567",
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.phonePad)
            #endif
            
            FormTextField(
                title: "Website",
                text: Binding(
                    get: { businessProfile.website ?? "" },
                    set: { businessProfile.website = $0.isEmpty ? nil : $0 }
                ),
                placeholder: "https://www.example.com",
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.URL)
            .textInputAutocapitalization(.never)
            #endif
        }
        
        Section("Business Address") {
            FormTextField(
                title: "Street Address",
                text: $address,
                placeholder: "123 Main Street",
                isEditing: isEditing
            )
            
            HStack(spacing: 12) {
                FormTextField(
                    title: "City",
                    text: $city,
                    placeholder: "New York",
                    isEditing: isEditing
                )
                
                FormTextField(
                    title: "State",
                    text: $state,
                    placeholder: "NY",
                    isEditing: isEditing
                )
            }
            
            HStack(spacing: 12) {
                FormTextField(
                    title: "Postal Code",
                    text: $postalCode,
                    placeholder: "10001",
                    isEditing: isEditing
                )
                #if os(iOS)
                .keyboardType(.numberPad)
                #endif
                
                FormTextField(
                    title: "Country",
                    text: $country,
                    placeholder: "United States",
                    isEditing: isEditing
                )
            }
        }
    }
    
    @ViewBuilder
    private var businessDetailsSection: some View {
        Section("Business Details") {
            FormTextField(
                title: "Tax ID / EIN",
                text: $taxIdString,
                placeholder: "12-3456789",
                isEditing: isEditing
            )
            
            FormTextField(
                title: "Registration Number",
                text: $registrationNumberString,
                placeholder: "Business registration number",
                isEditing: isEditing
            )
        }
    }
    
    @ViewBuilder
    private var brandingSection: some View {
        Section("Branding") {
            BusinessLogoRow(
                logoData: businessProfile.logo,
                isEditing: isEditing,
                onImageSelected: { imageData in
                    businessProfile.logo = imageData
                }
            )
            
            BusinessSignatureRow(
                signatureData: businessProfile.signature,
                isEditing: isEditing,
                onSignatureSelected: { signatureData in
                    businessProfile.signature = signatureData
                }
            )
        }
    }
    
    @ViewBuilder
    private var invoiceSettingsSection: some View {
        Section("Invoice Settings") {
            FormTextField(
                title: "Invoice Number Prefix",
                text: $invoiceNumberPrefixString,
                placeholder: "INV",
                isEditing: isEditing
            )
            
            FormTextField(
                title: "Next Invoice Number",
                text: $nextInvoiceNumberString,
                placeholder: "1",
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.numberPad)
            #endif
            
            if isEditing {
                // Invoice Number Format Picker
                HStack {
                    Text("Number Format")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Format", selection: $selectedInvoiceNumberFormat) {
                        ForEach(InvoiceNumberFormat.allCases, id: \.self) { format in
                            Text(format.displayName).tag(format)
                        }
                    }
                    .pickerStyle(.menu)
                }
                
                // Custom format options
                if selectedInvoiceNumberFormat == .custom {
                    Toggle("Include Year", isOn: $includeYearInInvoiceNumber)
                    Toggle("Include Month", isOn: $includeMonthInInvoiceNumber)
                }
                
                // Number padding
                HStack {
                    Text("Number Padding")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Picker("Padding", selection: $invoiceNumberPadding) {
                        ForEach(1...6, id: \.self) { padding in
                            Text("\(padding) digits").tag(padding)
                        }
                    }
                    .pickerStyle(.menu)
                }
            }
            
            if !isEditing {
                HStack {
                    Text("Next Invoice ID")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(businessProfile.generateNextInvoiceNumber())
                        .fontWeight(.medium)
                }
            }
        }
    }
    
    @ViewBuilder
    private var taxAndPaymentSection: some View {
        Section("Tax & Payment Settings") {
            if isEditing {
                Picker("Currency", selection: $businessProfile.currency) {
                    ForEach(Currency.allCases, id: \.self) { currency in
                        Text("\(currency.symbol) \(currency.name)")
                            .tag(currency)
                    }
                }
                .pickerStyle(.menu)
            } else {
                HStack {
                    Text("Currency")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text("\(businessProfile.currency.symbol) \(businessProfile.currency.name)")
                }
            }
            
            FormTextField(
                title: "Default Tax Rate (%)",
                text: $defaultTaxRateString,
                placeholder: "8.25",
                isEditing: isEditing
            )
            #if os(iOS)
            .keyboardType(.decimalPad)
            #endif
            
            if isEditing {
                Picker("Default Payment Terms", selection: $businessProfile.paymentTerms) {
                    ForEach(PaymentTerms.allCases, id: \.self) { terms in
                        Text(terms.displayName)
                            .tag(terms)
                    }
                }
                .pickerStyle(.menu)
            } else {
                HStack {
                    Text("Default Payment Terms")
                        .foregroundStyle(.secondary)
                    Spacer()
                    Text(businessProfile.paymentTerms.displayName)
                }
            }
        }
        
        if !isEditing && businessProfiles.count > 0 {
            Section {
                Button("Delete Business Profile", role: .destructive) {
                    showingDeleteConfirmation = true
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var isFormValid: Bool {
        !businessProfile.businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !businessProfile.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !businessProfile.email.isEmpty &&
        isValidEmail(businessProfile.email)
    }
    
    // MARK: - Methods
    
    private func loadExistingProfile() {
        if let existingProfile = businessProfiles.first {
            businessProfile = BusinessProfile(from: existingProfile)
            isEditing = false
        }
    }
    
    private func populateFormFields() {
        if let address = businessProfile.address {
            self.address = address.street
            self.city = address.city
            self.state = address.state
            self.postalCode = address.postalCode
            self.country = address.country
        }
        
        taxIdString = businessProfile.taxId ?? ""
        registrationNumberString = businessProfile.registrationNumber ?? ""
        defaultTaxRateString = businessProfile.defaultTaxRate == 0 ? "" : String(describing: businessProfile.defaultTaxRate)
        invoiceNumberPrefixString = businessProfile.invoiceNumberPrefix
        nextInvoiceNumberString = String(businessProfile.nextInvoiceNumber)
        selectedInvoiceNumberFormat = businessProfile.invoiceNumberFormat
        includeYearInInvoiceNumber = businessProfile.includeYearInInvoiceNumber
        includeMonthInInvoiceNumber = businessProfile.includeMonthInInvoiceNumber
        invoiceNumberPadding = businessProfile.invoiceNumberPadding
    }
    
    private func saveBusinessProfile() {
        isLoading = true
        
        Task {
            // Update address if any field is filled
            if !address.isEmpty || !city.isEmpty || !state.isEmpty || !postalCode.isEmpty || !country.isEmpty {
                businessProfile.address = Address(
                    street: address,
                    city: city,
                    state: state,
                    postalCode: postalCode,
                    country: country
                )
            }
            
            // Update other fields
            businessProfile.taxId = taxIdString.isEmpty ? nil : taxIdString
            businessProfile.registrationNumber = registrationNumberString.isEmpty ? nil : registrationNumberString
            
            if let taxRate = Decimal(string: defaultTaxRateString) {
                businessProfile.defaultTaxRate = taxRate
            }
            
            if !invoiceNumberPrefixString.isEmpty {
                businessProfile.invoiceNumberPrefix = invoiceNumberPrefixString
            }
            
            if let nextNumber = Int(nextInvoiceNumberString), nextNumber > 0 {
                businessProfile.nextInvoiceNumber = nextNumber
            }
            
            // Update invoice numbering format settings
            businessProfile.invoiceNumberFormat = selectedInvoiceNumberFormat
            businessProfile.includeYearInInvoiceNumber = includeYearInInvoiceNumber
            businessProfile.includeMonthInInvoiceNumber = includeMonthInInvoiceNumber
            businessProfile.invoiceNumberPadding = invoiceNumberPadding
            
            // Save to persistence layer
            await saveToDatabase()
            
            await MainActor.run {
                isLoading = false
                isEditing = false
            }
        }
    }
    
    private func saveToDatabase() async {
        // Find existing profile or create new one
        let existingProfile = businessProfiles.first
        
        if let existing = existingProfile {
            // Update existing profile
            existing.businessName = businessProfile.businessName
            existing.ownerName = businessProfile.ownerName
            existing.email = businessProfile.email
            existing.phone = businessProfile.phone
            existing.website = businessProfile.website
            existing.logoData = businessProfile.logo
            existing.signatureData = businessProfile.signature
            existing.taxNumber = businessProfile.taxId
            existing.registrationNumber = businessProfile.registrationNumber
            existing.invoicePrefix = businessProfile.invoiceNumberPrefix
            existing.nextInvoiceNumber = businessProfile.nextInvoiceNumber
            existing.invoiceNumberFormat = businessProfile.invoiceNumberFormat.rawValue
            existing.includeYearInInvoice = businessProfile.includeYearInInvoiceNumber
            existing.includeMonthInInvoice = businessProfile.includeMonthInInvoiceNumber
            existing.invoiceNumberPadding = businessProfile.invoiceNumberPadding
            existing.taxRate = businessProfile.defaultTaxRate
            existing.defaultCurrency = businessProfile.currency.rawValue
            existing.defaultPaymentTerms = businessProfile.paymentTerms.rawValue
            existing.updatedAt = Date()
            
            // Update address
            if let address = businessProfile.address {
                if let existingAddress = existing.address {
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
                    existing.address = newAddress
                    modelContext.insert(newAddress)
                }
            }
        } else {
            // Create new profile
            let newProfile = BusinessProfileEntity(
                businessName: businessProfile.businessName,
                ownerName: businessProfile.ownerName,
                email: businessProfile.email
            )
            
            newProfile.phone = businessProfile.phone
            newProfile.website = businessProfile.website
            newProfile.logoData = businessProfile.logo
            newProfile.signatureData = businessProfile.signature
            newProfile.taxNumber = businessProfile.taxId
            newProfile.registrationNumber = businessProfile.registrationNumber
            newProfile.invoicePrefix = businessProfile.invoiceNumberPrefix
            newProfile.nextInvoiceNumber = businessProfile.nextInvoiceNumber
            newProfile.invoiceNumberFormat = businessProfile.invoiceNumberFormat.rawValue
            newProfile.includeYearInInvoice = businessProfile.includeYearInInvoiceNumber
            newProfile.includeMonthInInvoice = businessProfile.includeMonthInInvoiceNumber
            newProfile.invoiceNumberPadding = businessProfile.invoiceNumberPadding
            newProfile.taxRate = businessProfile.defaultTaxRate
            newProfile.defaultCurrency = businessProfile.currency.rawValue
            newProfile.defaultPaymentTerms = businessProfile.paymentTerms.rawValue
            
            // Create address if provided
            if let address = businessProfile.address {
                let newAddress = AddressEntity(
                    street: address.street,
                    city: address.city,
                    state: address.state,
                    postalCode: address.postalCode,
                    country: address.country
                )
                newProfile.address = newAddress
                modelContext.insert(newAddress)
            }
            
            modelContext.insert(newProfile)
        }
        
        do {
            try modelContext.save()
            print("Business profile saved successfully")
        } catch {
            print("Failed to save business profile: \(error)")
        }
    }
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
}

// MARK: - Supporting Views

private struct FormTextField: View {
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

private struct BusinessLogoRow: View {
    let logoData: Data?
    let isEditing: Bool
    let onImageSelected: (Data?) -> Void
    
    @State private var showingLogoUpload = false
    
    var body: some View {
        HStack {
            Text("Business Logo")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let logoData = logoData, let image = loadImage(from: logoData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 40, height: 40)
                    .overlay {
                        Image(systemName: "photo")
                            .foregroundStyle(.gray)
                    }
            }
            
            if isEditing {
                Button(logoData == nil ? "Add" : "Change") {
                    showingLogoUpload = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .sheet(isPresented: $showingLogoUpload) {
            NavigationStack {
                LogoUploadView()
            }
        }
    }
    
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
}

private struct BusinessSignatureRow: View {
    let signatureData: Data?
    let isEditing: Bool
    let onSignatureSelected: (Data?) -> Void
    
    @State private var showingSignatureCapture = false
    
    var body: some View {
        HStack {
            Text("Business Signature")
                .foregroundStyle(.secondary)
            
            Spacer()
            
            if let signatureData = signatureData, let image = loadImage(from: signatureData) {
                image
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 30)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(.gray.opacity(0.2))
                    .frame(width: 60, height: 30)
                    .overlay {
                        Image(systemName: "signature")
                            .font(.caption)
                            .foregroundStyle(.gray)
                    }
            }
            
            if isEditing {
                Button(signatureData == nil ? "Add" : "Change") {
                    showingSignatureCapture = true
                }
                .font(.caption)
                .foregroundStyle(.blue)
            }
        }
        .sheet(isPresented: $showingSignatureCapture) {
            SignatureCaptureView()
        }
    }
    
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
}

#Preview {
    BusinessProfileView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}