import SwiftUI
import SwiftData
import InvoiceBuilderFeature

@main
struct InvoiceBuilderApp: App {
    @State private var appState = AppState()
    private let dataStack = SwiftDataStack.shared
    private let authService = AuthenticationService.shared
    private let templateService = InvoiceTemplateService.shared
    private let subscriptionService = SubscriptionService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(authService)
                .environment(templateService)
                .environment(subscriptionService)
                .modelContainer(dataStack.modelContainer)
        }
        #if os(macOS)
        .windowResizability(.contentSize)  
        .windowToolbarStyle(.unified)
        #endif
    }
}
