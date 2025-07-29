import SwiftUI
import InvoiceBuilderFeature

@main
struct InvoiceBuilderApp: App {
    @State private var appState = AppState()
    
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(appState)
        }
        #if os(macOS)
        .windowResizability(.contentSize)
        .windowToolbarStyle(.unified)
        #endif
    }
}
