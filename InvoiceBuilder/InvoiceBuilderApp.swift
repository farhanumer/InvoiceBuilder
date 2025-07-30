import SwiftUI
import SwiftData
import InvoiceBuilderFeature

@main
struct InvoiceBuilderApp: App {
    @State private var appState = AppState()
    private let dataStack = SwiftDataStack.shared
    private let authService = AuthenticationService.shared
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
                .environment(authService)
                .modelContainer(dataStack.modelContainer)
        }
        #if os(macOS)
        .windowResizability(.contentSize)  
        .windowToolbarStyle(.unified)
        #endif
    }
}
