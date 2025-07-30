import SwiftUI
import PDFKit
import UniformTypeIdentifiers

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

@MainActor
public final class PDFGenerationService: @unchecked Sendable {
    public static let shared = PDFGenerationService()
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Generate PDF data for an invoice
    public func generateInvoicePDF(
        invoice: Invoice,
        businessProfile: BusinessProfile,
        template: InvoiceTemplate? = nil
    ) async throws -> Data {
        
        let renderer = await createInvoicePDFRenderer(
            invoice: invoice,
            businessProfile: businessProfile,
            template: template
        )
        
        return try await withCheckedThrowingContinuation { continuation in
            Task { @MainActor in
                do {
                    // Use ImageRenderer to render to PDF
                    let url = URL.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathExtension("pdf")
                    renderer.render { size, context in
                        var box = CGRect(x: 0, y: 0, width: size.width, height: size.height)
                        guard let pdf = CGContext(url as CFURL, mediaBox: &box, nil) else {
                            return
                        }
                        pdf.beginPDFPage(nil)
                        context(pdf)
                        pdf.endPDFPage()
                        pdf.closePDF()
                    }
                    
                    let pdfData = try Data(contentsOf: url)
                    try FileManager.default.removeItem(at: url)
                    continuation.resume(returning: pdfData)
                } catch {
                    continuation.resume(throwing: PDFGenerationError.renderingFailed(error))
                }
            }
        }
    }
    
    /// Export invoice PDF to file system and return URL
    public func exportInvoicePDF(
        invoice: Invoice,
        businessProfile: BusinessProfile,
        template: InvoiceTemplate? = nil,
        fileName: String? = nil
    ) async throws -> URL {
        
        let pdfData = try await generateInvoicePDF(
            invoice: invoice,
            businessProfile: businessProfile,
            template: template
        )
        
        let fileName = fileName ?? generateFileName(for: invoice)
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let fileURL = documentsURL.appendingPathComponent(fileName)
        
        do {
            try pdfData.write(to: fileURL)
            return fileURL
        } catch {
            throw PDFGenerationError.fileWriteFailed(error)
        }
    }
    
    /// Share invoice PDF using system share sheet
    #if os(iOS)
    public func shareInvoicePDF(
        invoice: Invoice,
        businessProfile: BusinessProfile,
        template: InvoiceTemplate? = nil,
        from viewController: UIViewController? = nil
    ) async throws {
        
        let fileURL = try await exportInvoicePDF(
            invoice: invoice,
            businessProfile: businessProfile,
            template: template
        )
        
        let activityViewController = UIActivityViewController(
            activityItems: [fileURL],
            applicationActivities: nil
        )
        
        // Configure for iPad
        if let popover = activityViewController.popoverPresentationController {
            if let viewController = viewController {
                popover.sourceView = viewController.view
                popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
            }
        }
        
        // Present the share sheet
        if let viewController = viewController {
            viewController.present(activityViewController, animated: true)
        } else if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityViewController, animated: true)
        }
    }
    #endif
    
    #if os(macOS)
    public func shareInvoicePDF(
        invoice: Invoice,
        businessProfile: BusinessProfile,
        template: InvoiceTemplate? = nil
    ) async throws {
        
        let fileURL = try await exportInvoicePDF(
            invoice: invoice,
            businessProfile: businessProfile,
            template: template
        )
        
        let sharingServicePicker = NSSharingServicePicker(items: [fileURL])
        if let window = NSApplication.shared.mainWindow {
            sharingServicePicker.show(relativeTo: .zero, of: window.contentView!, preferredEdge: .minY)
        }
    }
    #endif
    
    // MARK: - Private Methods
    
    private func createInvoicePDFRenderer(
        invoice: Invoice,
        businessProfile: BusinessProfile,
        template: InvoiceTemplate?
    ) async -> ImageRenderer<InvoicePDFView> {
        
        let defaultTemplate = InvoiceTemplate(
            name: "modern-blue",
            displayName: "Modern Blue",
            templateDescription: "A clean, modern template with blue accents",
            isDefault: true,
            primaryColor: "#007AFF",
            secondaryColor: "#666666",
            accentColor: "#007AFF"
        )
        
        let pdfView = InvoicePDFView(
            invoice: invoice,
            businessProfile: businessProfile,
            template: template ?? defaultTemplate
        )
        
        let renderer = ImageRenderer(content: pdfView)
        renderer.proposedSize = .init(width: 612, height: 792) // Standard US Letter size in points
        
        return renderer
    }
    
    private func generateFileName(for invoice: Invoice) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: invoice.date)
        
        let clientName = invoice.client.name
            .replacingOccurrences(of: " ", with: "_")
            .replacingOccurrences(of: "/", with: "-")
        
        return "Invoice_\(invoice.invoiceNumber)_\(clientName)_\(dateString).pdf"
    }
}

// MARK: - PDF Generation Errors

public enum PDFGenerationError: LocalizedError {
    case renderingFailed(Error)
    case fileWriteFailed(Error)
    case invalidData
    
    public var errorDescription: String? {
        switch self {
        case .renderingFailed(let error):
            return "Failed to render PDF: \(error.localizedDescription)"
        case .fileWriteFailed(let error):
            return "Failed to write PDF file: \(error.localizedDescription)"
        case .invalidData:
            return "Invalid PDF data generated"
        }
    }
}

// MARK: - Invoice PDF View

private struct InvoicePDFView: View {
    let invoice: Invoice
    let businessProfile: BusinessProfile
    let template: InvoiceTemplate
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with business info and logo
            headerSection
            
            Divider()
                .padding(.vertical, 20)
            
            // Invoice details and client info
            invoiceDetailsSection
            
            Spacer(minLength: 20)
            
            // Items table
            itemsTableSection
            
            Spacer(minLength: 20)
            
            // Totals section
            totalsSection
            
            Spacer(minLength: 20)
            
            // Footer with notes and signature
            footerSection
            
            Spacer()
        }
        .padding(40)
        .frame(width: 612, height: 792) // US Letter size
        .background(Color.white)
        .foregroundStyle(Color.black)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        HStack(alignment: .top, spacing: 20) {
            // Business logo
            if let logoData = businessProfile.logo,
               let logoImage = loadImage(from: logoData) {
                logoImage
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: 120, maxHeight: 80)
            }
            
            Spacer()
            
            // Business information
            VStack(alignment: .trailing, spacing: 4) {
                Text(businessProfile.businessName)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(businessProfile.ownerName)
                    .font(.subheadline)
                
                if let address = businessProfile.address {
                    Group {
                        Text(address.street)
                        Text("\(address.city), \(address.state) \(address.postalCode)")
                        Text(address.country)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                
                Text(businessProfile.email)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                
                if let phone = businessProfile.phone {
                    Text(phone)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
    
    @ViewBuilder
    private var invoiceDetailsSection: some View {
        HStack(alignment: .top, spacing: 40) {
            // Invoice details
            VStack(alignment: .leading, spacing: 8) {
                Text("INVOICE")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
                
                Group {
                    HStack {
                        Text("Invoice Number:")
                            .fontWeight(.medium)
                        Text(invoice.invoiceNumber)
                    }
                    
                    HStack {
                        Text("Issue Date:")
                            .fontWeight(.medium)
                        Text(invoice.date, style: .date)
                    }
                    
                    HStack {
                        Text("Due Date:")
                            .fontWeight(.medium)
                        Text(invoice.dueDate, style: .date)
                    }
                    
                    if let poNumber = invoice.poNumber {
                        HStack {
                            Text("PO Number:")
                                .fontWeight(.medium)
                            Text(poNumber)
                        }
                    }
                }
                .font(.subheadline)
            }
            
            Spacer()
            
            // Client information
            VStack(alignment: .leading, spacing: 8) {
                Text("BILL TO:")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
                
                Group {
                    Text(invoice.client.name)
                        .fontWeight(.semibold)
                    
                    if let company = invoice.client.company {
                        Text(company)
                    }
                    
                    Text(invoice.client.email)
                    
                    if let phone = invoice.client.phone {
                        Text(phone)
                    }
                    
                    if let address = invoice.client.address {
                        Text(address.street)
                        Text("\(address.city), \(address.state) \(address.postalCode)")
                        Text(address.country)
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.primary)
            }
        }
    }
    
    @ViewBuilder
    private var itemsTableSection: some View {
        VStack(spacing: 0) {
            // Table header
            HStack {
                Text("DESCRIPTION")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Text("QTY")
                    .fontWeight(.bold)
                    .frame(width: 60, alignment: .center)
                
                Text("RATE")
                    .fontWeight(.bold)
                    .frame(width: 80, alignment: .trailing)
                
                Text("AMOUNT")
                    .fontWeight(.bold)
                    .frame(width: 100, alignment: .trailing)
            }
            .padding(.vertical, 12)
            .background((Color(hex: template.primaryColor) ?? .blue).opacity(0.1))
            .font(.caption)
            .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
            
            // Table rows
            ForEach(Array(invoice.items.enumerated()), id: \.element.id) { index, item in
                VStack(spacing: 0) {
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .fontWeight(.medium)
                            
                            if !item.description.isEmpty {
                                Text(item.description)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text(formatDecimal(item.quantity))
                            .frame(width: 60, alignment: .center)
                        
                        Text(formatCurrency(item.rate))
                            .frame(width: 80, alignment: .trailing)
                        
                        Text(formatCurrency(item.total))
                            .fontWeight(.medium)
                            .frame(width: 100, alignment: .trailing)
                    }
                    .padding(.vertical, 8)
                    .font(.subheadline)
                    
                    if index < invoice.items.count - 1 {
                        Divider()
                    }
                }
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
        )
    }
    
    @ViewBuilder
    private var totalsSection: some View {
        HStack {
            Spacer()
            
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 40) {
                    Text("Subtotal:")
                        .fontWeight(.medium)
                    Text(invoice.formattedSubtotal)
                }
                
                if invoice.taxAmount > 0 {
                    HStack(spacing: 40) {
                        Text("Tax:")
                            .fontWeight(.medium)
                        Text(invoice.formattedTaxAmount)
                    }
                }
                
                if invoice.discountAmount > 0 {
                    HStack(spacing: 40) {
                        Text("Discount:")
                            .fontWeight(.medium)
                        Text("-\(invoice.formattedDiscountAmount)")
                            .foregroundStyle(.orange)
                    }
                }
                
                Divider()
                    .frame(width: 150)
                
                HStack(spacing: 40) {
                    Text("TOTAL:")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
                    
                    Text(invoice.formattedTotal)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
                }
            }
            .font(.subheadline)
        }
    }
    
    @ViewBuilder
    private var footerSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let notes = invoice.notes, !notes.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Notes:")
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
                    
                    Text(notes)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            if let paymentTerms = invoice.paymentTerms, !paymentTerms.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Payment Terms:")
                        .fontWeight(.bold)
                        .foregroundStyle(Color(hex: template.primaryColor) ?? .blue)
                    
                    Text(paymentTerms)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 20)
            
            // Signature section
            HStack {
                Spacer()
                
                VStack(spacing: 8) {
                    if let signatureData = businessProfile.signature,
                       let signatureImage = loadImage(from: signatureData) {
                        signatureImage
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxWidth: 200, maxHeight: 60)
                    }
                    
                    Rectangle()
                        .fill(Color.black)
                        .frame(width: 200, height: 1)
                    
                    Text(businessProfile.ownerName)
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Text("Authorized Signature")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
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
        formatter.currencyCode = "USD" // TODO: Get from business profile
        return formatter.string(from: amount as NSDecimalNumber) ?? "$0.00"
    }
    
    private func formatDecimal(_ amount: Decimal) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber) ?? "0"
    }
}

