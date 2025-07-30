import SwiftUI
import SwiftData

#if os(iOS)
import PencilKit
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
public struct SignatureCaptureView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var signatureImage: Image?
    @State private var signatureData: Data?
    @State private var showingAlert = false
    @State private var alertMessage = ""
    #if os(iOS)
    @State private var canvasView = PKCanvasView()
    #endif
    @State private var isDrawing = false
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Instructions
                instructionsSection
                
                // Signature canvas
                signatureCanvasSection
                
                // Controls
                controlsSection
            }
            .navigationTitle("Signature")
            #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveSignature()
                    }
                    .disabled(signatureImage == nil)
                }
            }
            .alert("Signature", isPresented: $showingAlert) {
                Button("OK") {
                    if alertMessage.contains("saved") {
                        dismiss()
                    }
                }
            } message: {
                Text(alertMessage)
            }
        }
        .task {
            loadSavedSignature()
        }
    }
    
    // MARK: - View Components
    
    @ViewBuilder
    private var instructionsSection: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "signature")
                    .font(.title2)
                    .foregroundStyle(.blue)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Digital Signature")
                        .font(.headline)
                    
                    Text("Draw your signature in the area below")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            
            Divider()
        }
        .background(.regularMaterial)
    }
    
    @ViewBuilder
    private var signatureCanvasSection: some View {
        ZStack {
            // Background
            Rectangle()
                .fill(.white)
                .border(.gray.opacity(0.3), width: 1)
            
            // Canvas or preview
            if let signatureImage = signatureImage {
                signatureImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(8)
            } else {
                #if os(iOS)
                SignatureCanvasView(
                    canvasView: $canvasView,
                    onSignatureChanged: { image, data in
                        self.signatureImage = image
                        self.signatureData = data
                    }
                )
                #else
                macOSSignatureView
                #endif
            }
        }
        .frame(maxHeight: 200)
        .padding(.horizontal, 20)
    }
    
    #if os(macOS)
    @ViewBuilder
    private var macOSSignatureView: some View {
        VStack(spacing: 16) {
            Image(systemName: "scribble.variable")
                .font(.system(size: 48))
                .foregroundStyle(.gray)
            
            Text("Signature capture is not available on macOS")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Text("You can upload a signature image instead")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding()
    }
    #endif
    
    @ViewBuilder
    private var controlsSection: some View {
        VStack(spacing: 16) {
            Divider()
            
            HStack(spacing: 16) {
                // Clear button
                Button {
                    clearSignature()
                } label: {
                    Label("Clear", systemImage: "eraser")
                        .font(.subheadline)
                        .foregroundColor(.red)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(.red.opacity(0.1))
                        .cornerRadius(12)
                }
                
                #if os(macOS)
                // Upload button for macOS
                Button {
                    uploadSignatureImage()
                } label: {
                    Label("Upload Image", systemImage: "photo")
                        .font(.subheadline)
                        .foregroundColor(.blue)
                        .frame(height: 44)
                        .frame(maxWidth: .infinity)
                        .background(.blue.opacity(0.1))
                        .cornerRadius(12)
                }
                #endif
            }
            .padding(.horizontal, 20)
            
            // Usage guidelines
            VStack(alignment: .leading, spacing: 8) {
                Text("Signature Guidelines")
                    .font(.caption)
                    .fontWeight(.medium)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                VStack(alignment: .leading, spacing: 4) {
                    SignatureGuideline(
                        icon: "checkmark.circle.fill",
                        text: "Use a dark pen or stylus for best results",
                        color: .green
                    )
                    
                    SignatureGuideline(
                        icon: "checkmark.circle.fill",
                        text: "Sign within the bordered area",
                        color: .green
                    )
                    
                    SignatureGuideline(
                        icon: "info.circle.fill",
                        text: "Your signature will appear on invoices",
                        color: .blue
                    )
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(.regularMaterial)
    }
    
    // MARK: - Methods
    
    private func clearSignature() {
        signatureImage = nil
        signatureData = nil
        
        #if os(iOS)
        canvasView.drawing = PKDrawing()
        #endif
    }
    
    #if os(macOS)
    private func uploadSignatureImage() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.allowedContentTypes = [.image]
        
        if panel.runModal() == .OK {
            guard let url = panel.url else { return }
            
            do {
                let data = try Data(contentsOf: url)
                self.signatureData = data
                if let nsImage = NSImage(data: data) {
                    self.signatureImage = Image(nsImage: nsImage)
                }
            } catch {
                alertMessage = "Failed to load signature image: \(error.localizedDescription)"
                showingAlert = true
            }
        }
    }
    #endif
    
    private func saveSignature() {
        guard let signatureData = signatureData else {
            alertMessage = "No signature to save"
            showingAlert = true
            return
        }
        
        do {
            let businessProfile = try getOrCreateBusinessProfile()
            businessProfile.signatureData = signatureData
            businessProfile.updatedAt = Date()
            try modelContext.save()
            
            alertMessage = "Signature saved successfully"
            showingAlert = true
        } catch {
            alertMessage = "Failed to save signature: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func loadSavedSignature() {
        do {
            let businessProfile = try getOrCreateBusinessProfile()
            if let signatureData = businessProfile.signatureData {
                self.signatureData = signatureData
                
                #if os(iOS)
                if let uiImage = UIImage(data: signatureData) {
                    self.signatureImage = Image(uiImage: uiImage)
                }
                #elseif os(macOS)
                if let nsImage = NSImage(data: signatureData) {
                    self.signatureImage = Image(nsImage: nsImage)
                }
                #endif
            }
        } catch {
            print("Failed to load saved signature: \(error)")
        }
    }
    
    private func getOrCreateBusinessProfile() throws -> BusinessProfileEntity {
        let descriptor = FetchDescriptor<BusinessProfileEntity>()
        let profiles = try modelContext.fetch(descriptor)
        
        if let existingProfile = profiles.first {
            return existingProfile
        } else {
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

// MARK: - iOS Signature Canvas

#if os(iOS)
struct SignatureCanvasView: UIViewRepresentable {
    @Binding var canvasView: PKCanvasView
    let onSignatureChanged: (Image, Data) -> Void
    
    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 2)
        canvasView.delegate = context.coordinator
        canvasView.backgroundColor = .clear
        return canvasView
    }
    
    func updateUIView(_ uiView: PKCanvasView, context: Context) {
        // Updates handled by coordinator
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let parent: SignatureCanvasView
        
        init(_ parent: SignatureCanvasView) {
            self.parent = parent
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            guard !canvasView.drawing.bounds.isEmpty else { return }
            
            let image = canvasView.drawing.image(from: canvasView.drawing.bounds, scale: 2.0)
            let data = image.pngData() ?? Data()
            
            parent.onSignatureChanged(Image(uiImage: image), data)
        }
    }
}
#endif

// MARK: - Supporting Views

private struct SignatureGuideline: View {
    let icon: String
    let text: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 12)
            
            Text(text)
                .font(.caption2)
                .foregroundStyle(.secondary)
            
            Spacer()
        }
    }
}

#Preview {
    SignatureCaptureView()
        .modelContainer(SwiftDataStack.shared.modelContainer)
}