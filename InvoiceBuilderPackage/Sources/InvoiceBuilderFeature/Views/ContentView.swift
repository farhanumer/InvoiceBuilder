import SwiftUI

public struct ContentView: View {
    @State private var appState = AppState()
    
    public var body: some View {
        RootView()
            .environment(appState)
            .environment(AuthenticationService.shared)
    }
    
    public init() {}
}
