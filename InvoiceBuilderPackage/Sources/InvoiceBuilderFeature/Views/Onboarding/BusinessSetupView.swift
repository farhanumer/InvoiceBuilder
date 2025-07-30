import SwiftUI

#if os(iOS)
import UIKit
#endif

public struct BusinessSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var businessProfile = BusinessProfile(
        businessName: "",
        ownerName: "",
        email: ""
    )
    // PhotosPicker removed for now
    @State private var logoImage: Image?
    @State private var showingImagePicker = false
    @State private var isLoading = false
    @State private var currentStep = 0
    
    // Additional properties for the form
    @State private var industry = ""
    @State private var businessDescription = ""
    @State private var address = ""
    @State private var city = ""
    @State private var state = ""
    @State private var zipCode = ""
    @State private var country = ""
    @State private var defaultTaxRateString = ""
    @State private var defaultPaymentTermsString = ""
    
    private let steps = ["Basic Info", "Contact", "Branding", "Settings"]
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress header
                VStack(spacing: 16) {
                    // Step indicator
                    HStack {
                        ForEach(0..<steps.count, id: \.self) { index in
                            VStack(spacing: 8) {
                                Circle()
                                    .fill(index <= currentStep ? .blue : .gray.opacity(0.3))
                                    .frame(width: 12, height: 12)
                                
                                Text(steps[index])
                                    .font(.caption2)
                                    .foregroundStyle(index <= currentStep ? .blue : .secondary)
                            }
                            
                            if index < steps.count - 1 {
                                Rectangle()
                                    .fill(index < currentStep ? .blue : .gray.opacity(0.3))
                                    .frame(height: 1)
                                    .padding(.horizontal, 4)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    Text("Step \(currentStep + 1) of \(steps.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)
                .background(.regularMaterial)
                
                // Step content
                TabView(selection: $currentStep) {
                    basicInfoStep.tag(0)
                    contactStep.tag(1)
                    brandingStep.tag(2)
                    settingsStep.tag(3)
                }
                #if os(iOS)
                .tabViewStyle(.page(indexDisplayMode: .never))
                #endif
                .animation(.easeInOut(duration: 0.3), value: currentStep)
                
                // Navigation buttons
                VStack(spacing: 16) {
                    HStack(spacing: 16) {
                        if currentStep > 0 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(.bordered)
                        }
                        
                        Spacer()
                        
                        Button(currentStep == steps.count - 1 ? "Complete Setup" : "Continue") {
                            if currentStep == steps.count - 1 {
                                completeSetup()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!canContinue)
                    }
                    
                    Button("Save and Continue Later") {
                        saveProgress()
                        dismiss()
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                .background(.regularMaterial)
            }
        }
        .navigationTitle("Business Setup")
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
        .overlay {
            if isLoading {
                LoadingOverlay()
            }
        }
    }
    
    // MARK: - Step Views
    
    @ViewBuilder
    private var basicInfoStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "building.2.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Business Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Tell us about your business")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    FormField(
                        title: "Business Name",
                        text: $businessProfile.businessName,
                        placeholder: "Acme Corporation"
                    )
                    
                    FormField(
                        title: "Owner Name",
                        text: $businessProfile.ownerName,
                        placeholder: "John Doe"
                    )
                    
                    FormField(
                        title: "Industry",
                        text: $industry,
                        placeholder: "Consulting, Design, etc."
                    )
                    
                    FormField(
                        title: "Business Description",
                        text: $businessDescription,
                        placeholder: "Brief description of your business",
                        axis: .vertical,
                        lineLimit: 3
                    )
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var contactStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "location.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Contact Information")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("How can clients reach you?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    FormField(
                        title: "Email Address",
                        text: $businessProfile.email,
                        placeholder: "business@example.com"
                    )
                    
                    FormField(
                        title: "Phone Number",
                        text: Binding(
                            get: { businessProfile.phone ?? "" },
                            set: { businessProfile.phone = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "+1 (555) 123-4567"
                    )
                    
                    FormField(
                        title: "Website",
                        text: Binding(
                            get: { businessProfile.website ?? "" },
                            set: { businessProfile.website = $0.isEmpty ? nil : $0 }
                        ),
                        placeholder: "https://www.example.com"
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Business Address")
                            .font(.headline)
                        
                        FormField(
                            title: "Street Address",
                            text: $address,
                            placeholder: "123 Main Street"
                        )
                        
                        HStack(spacing: 12) {
                            FormField(
                                title: "City",
                                text: $city,
                                placeholder: "New York"
                            )
                            
                            FormField(
                                title: "State",
                                text: $state,
                                placeholder: "NY"
                            )
                        }
                        
                        HStack(spacing: 12) {
                            FormField(
                                title: "ZIP Code",
                                text: $zipCode,
                                placeholder: "10001"
                            )
                            
                            FormField(
                                title: "Country",
                                text: $country,
                                placeholder: "United States"
                            )
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var brandingStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "paintbrush.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Branding & Logo")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Make your invoices look professional")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 20) {
                    // Logo upload section
                    VStack(spacing: 12) {
                        Text("Business Logo")
                            .font(.headline)
                        
                        BusinessSetupLogoView(
                            logoImage: logoImage,
                            onImageSelected: { 
                                // Image selection will be implemented later
                            }
                        )
                    }
                    
                    // Color scheme section - will be implemented later
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Brand Colors")
                            .font(.headline)
                        
                        Text("Custom brand colors will be available in a future update")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    @ViewBuilder
    private var settingsStep: some View {
        ScrollView {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "gearshape.fill")
                        .font(.system(size: 50))
                        .foregroundStyle(.blue)
                    
                    Text("Business Settings")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("Configure your preferences")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.top, 20)
                
                VStack(spacing: 16) {                    
                    FormField(
                        title: "Tax Rate (%)",
                        text: $defaultTaxRateString,
                        placeholder: "8.25"
                    )
                    
                    FormField(
                        title: "Payment Terms (Days)",
                        text: $defaultPaymentTermsString,
                        placeholder: "30"
                    )
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Currency")
                            .font(.headline)
                        
                        Picker("Currency", selection: $businessProfile.currency) {
                            ForEach(Currency.allCases, id: \.self) { currency in
                                Text("\(currency.symbol) \(currency.name)")
                                    .tag(currency)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Payment Terms")
                            .font(.headline)
                        
                        Picker("Payment Terms", selection: $businessProfile.paymentTerms) {
                            ForEach(PaymentTerms.allCases, id: \.self) { terms in
                                Text(terms.displayName)
                                    .tag(terms)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
            }
            .padding(.horizontal, 20)
        }
    }
    
    // MARK: - Computed Properties
    
    private var canContinue: Bool {
        switch currentStep {
        case 0:
            return !businessProfile.businessName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
                   !businessProfile.ownerName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        case 1:
            return !businessProfile.email.isEmpty && isValidEmail(businessProfile.email)
        case 2:
            return true // Branding is optional
        case 3:
            return true // Settings have defaults
        default:
            return false
        }
    }
    
    // MARK: - Methods
    
    // Image loading will be implemented later
    
    private func isValidEmail(_ email: String) -> Bool {
        let emailRegex = #"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$"#
        return email.range(of: emailRegex, options: .regularExpression) != nil
    }
    
    private func saveProgress() {
        // Save business profile to persistence layer
        // This would integrate with your data persistence service
        print("Saving business profile progress...")
    }
    
    private func completeSetup() {
        isLoading = true
        
        Task {
            // Save the completed business profile
            saveProgress()
            
            // Mark business setup as completed
            UserDefaults.standard.set(true, forKey: "hasCompletedBusinessSetup")
            
            await MainActor.run {
                isLoading = false
                dismiss()
            }
        }
    }
}

// MARK: - Supporting Views

private struct FormField: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var axis: Axis = .horizontal
    var lineLimit: Int = 1
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
            
            TextField(placeholder, text: $text, axis: axis)
                .textFieldStyle(.roundedBorder)
                .lineLimit(lineLimit, reservesSpace: axis == .vertical)
        }
    }
}

private struct BusinessSetupLogoView: View {
    let logoImage: Image?
    let onImageSelected: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.1))
                .stroke(.gray.opacity(0.3), lineWidth: 1)
                .frame(height: 100)
                .overlay {
                    if let logoImage = logoImage {
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(8)
                    } else {
                        VStack(spacing: 8) {
                            Image(systemName: "photo.badge.plus")
                                .font(.title2)
                                .foregroundStyle(.gray)
                            
                            Text("Upload Logo")
                                .font(.caption)
                                .foregroundStyle(.gray)
                        }
                    }
                }
            
            #if os(iOS)            
            Button {
                // For now, just show a placeholder
                // PhotosPicker will be implemented later
            } label: {
                Text(logoImage == nil ? "Choose Logo (Coming Soon)" : "Change Logo")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            #else
            Button {
                // macOS file picker implementation would go here
            } label: {
                Text(logoImage == nil ? "Choose Logo" : "Change Logo")
                    .font(.subheadline)
                    .foregroundStyle(.blue)
            }
            #endif
        }
    }
}

// Business Profile extensions removed - using the model properties directly

#Preview {
    BusinessSetupView()
}