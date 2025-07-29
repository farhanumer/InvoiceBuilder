import SwiftUI

public struct ContentView: View {
    @State private var viewState: ViewState = .loading
    
    enum ViewState {
        case loading
        case loaded
        case error(String)
    }
    
    public var body: some View {
        NavigationStack {
            switch viewState {
            case .loading:
                ProgressView("Loading Invoice Builder...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            case .loaded:
                VStack(spacing: 20) {
                    Text("Invoice Builder")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Professional invoicing made simple")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Button("Get Started") {
                        // Navigation logic will be added later
                    }
                    .buttonStyle(.borderedProminent)
                }
                .padding()
            case .error(let message):
                VStack {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.orange)
                    Text("Error: \(message)")
                        .multilineTextAlignment(.center)
                }
                .padding()
            }
        }
        .task {
            // Simulate loading
            try? await Task.sleep(for: .seconds(1))
            viewState = .loaded
        }
    }
    
    public init() {}
}
