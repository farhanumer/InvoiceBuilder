import SwiftUI
import SwiftData

#if os(iOS)
import PhotosUI
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
public struct LogoUploadView: View {
    @Environment(\.modelContext) private var modelContext
    
    @State private var logoImage: Image?
    @State private var logoData: Data?
    @State private var showingImagePicker = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    #if os(iOS)
    @State private var photosPickerItem: PhotosPickerItem?
    #endif
    
    private var logoButtonText: String {
        logoImage == nil ? "Choose Logo" : "Change Logo"
    }
    
    public init() {}
    
    public var body: some View {
        VStack(spacing: 20) {
            // Logo preview section
            logoPreviewSection
            
            // Upload controls
            uploadControlsSection
            
            // Logo management options
            if logoImage != nil {
                logoManagementSection
            }
            
            // Usage guidelines
            guidelinesSection
        }
        .navigationTitle("Business Logo")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
        #if os(iOS)
        .onChange(of: photosPickerItem) { _, newItem in
            loadImage(from: newItem)
        }
        #endif
        .alert("Logo Upload", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        .task {
            loadSavedLogo()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var logoPreviewSection: some View {
        VStack(spacing: 16) {
            Text("Business Logo")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            RoundedRectangle(cornerRadius: 16)
                .fill(.gray.opacity(0.1))
                .stroke(.gray.opacity(0.3), lineWidth: 1)
                .frame(height: 200)
                .overlay {
                    if let logoImage = logoImage {
                        logoImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .padding(16)
                    } else {
                        logoPlaceholder
                    }
                }
        }
    }
    
    @ViewBuilder
    private var logoPlaceholder: some View {
        VStack(spacing: 16) {
            Image(systemName: "photo.badge.plus")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            VStack(spacing: 4) {
                Text("No Logo Added")
                    .font(.headline)
                    .foregroundStyle(.primary)
                
                Text("Upload your business logo to personalize your invoices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
        }
        .padding()
    }
    
    @ViewBuilder
    private var uploadControlsSection: some View {
        VStack(spacing: 12) {
            #if os(iOS)
            PhotosPicker(
                selection: $photosPickerItem,
                matching: .images,
                photoLibrary: .shared()
            ) {
                Label(
                    "Choose Logo",
                    systemImage: "photo.on.rectangle.angled"
                )
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.blue)
                .cornerRadius(12)
            }
            #else
            Button {
                showMacOSFilePicker()
            } label: {
                Label(
                    "Choose Logo",
                    systemImage: "photo.on.rectangle.angled"
                )
                .font(.headline)
                .foregroundColor(.white)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.blue)
                .cornerRadius(12)
            }
            #endif
            
            Button {
                takePhoto()
            } label: {
                Label("Take Photo", systemImage: "camera")
                    .font(.subheadline)
                    .foregroundColor(.blue)
                    .frame(height: 44)
                    .frame(maxWidth: .infinity)
                    .background(.blue.opacity(0.1))
                    .cornerRadius(12)
            }
            #if os(macOS)
            .disabled(true) // Camera not available on macOS
            #endif
        }
    }
    
    @ViewBuilder
    private var logoManagementSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text("Logo Management")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            HStack(spacing: 12) {
                Button {
                    removeLogo()
                } label: {
                    Label("Remove Logo", systemImage: "trash")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                Button {
                    saveLogo()
                } label: {
                    Label("Save Logo", systemImage: "checkmark")
                        .font(.subheadline)
                        .foregroundColor(.green)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(.green.opacity(0.1))
                        .cornerRadius(12)
                }
            }
        }
    }
    
    @ViewBuilder
    private var guidelinesSection: some View {
        VStack(spacing: 12) {
            Divider()
            
            Text("Logo Guidelines")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            VStack(alignment: .leading, spacing: 8) {
                GuidelineItem(
                    icon: "checkmark.circle.fill",
                    text: "Use PNG or JPEG format",
                    color: .green
                )
                
                GuidelineItem(
                    icon: "checkmark.circle.fill",
                    text: "Recommended size: 500x500 pixels or larger",
                    color: .green
                )
                
                GuidelineItem(
                    icon: "checkmark.circle.fill",
                    text: "Square aspect ratio works best",
                    color: .green
                )
                
                GuidelineItem(
                    icon: "info.circle.fill",
                    text: "Transparent backgrounds are supported",
                    color: .blue
                )
            }
        }
    }
    
    // MARK: - Methods
    
    #if os(iOS)
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item = item else { return }
        
        Task {
            do {
                if let data = try await item.loadTransferable(type: Data.self) {
                    await MainActor.run {
                        self.logoData = data
                        if let uiImage = UIImage(data: data) {
                            self.logoImage = Image(uiImage: uiImage)
                        }
                    }
                }
            } catch {
                await MainActor.run {
                    alertMessage = "Failed to load image: \(error.localizedDescription)"
                    showingAlert = true
                }
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
                self.logoData = data
                if let nsImage = NSImage(data: data) {
                    self.logoImage = Image(nsImage: nsImage)
                }
            } catch {
                alertMessage = "Failed to load image: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    #endif
    
    private func takePhoto() {
        #if os(iOS)
        // Implementation for camera capture would go here
        // For now, show a placeholder message
        alertMessage = "Camera functionality will be available in a future update"
        showingAlert = true
        #endif
    }
    
    private func saveLogo() {
        guard let logoData = logoData else {
            alertMessage = "No logo to save"
            showingAlert = true
            return
        }
        
        // Save logo to business profile
        do {
            let businessProfile = try getOrCreateBusinessProfile()
            businessProfile.logoData = logoData
            try modelContext.save()
            
            alertMessage = "Logo saved successfully"
            showingAlert = true
        } catch {
            alertMessage = "Failed to save logo: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func removeLogo() {
        logoImage = nil
        logoData = nil
        
        // Remove logo from business profile
        do {
            let businessProfile = try getOrCreateBusinessProfile()
            businessProfile.logoData = nil
            try modelContext.save()
            
            alertMessage = "Logo removed successfully"
            showingAlert = true
        } catch {
            alertMessage = "Failed to remove logo: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func loadSavedLogo() {
        do {
            let businessProfile = try getOrCreateBusinessProfile()
            if let logoData = businessProfile.logoData {
                self.logoData = logoData
                
                #if os(iOS)
                if let uiImage = UIImage(data: logoData) {
                    self.logoImage = Image(uiImage: uiImage)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: logoData) {
                    self.logoImage = Image(nsImage: nsImage)
                }
                #endif
            }
        } catch {
            print("Failed to load saved logo: \(error)")
        }
    }
    
    private func getOrCreateBusinessProfile() throws -> BusinessProfileEntity {
        let descriptor = FetchDescriptor<BusinessProfileEntity>()
        let profiles = try modelContext.fetch(descriptor)
        
        if let existingProfile = profiles.first {
            return existingProfile
        } else {
            // Create a new business profile if none exists
            let newProfile = BusinessProfileEntity(
                businessName: "",
                ownerName: "",
                email: ""
            )
            modelContext.insert(newProfile)
            return newProfile
        }
    }
}

// MARK: - Supporting Views

private struct GuidelineItem: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 16)
            
            Text(text)
                .font(.caption)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    NavigationStack {
        LogoUploadView()
    }
    .modelContainer(SwiftDataStack.shared.modelContainer)
}