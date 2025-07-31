import Foundation
import Network

@Observable
public final class NetworkMonitor: @unchecked Sendable {
    public static let shared = NetworkMonitor()
    
    private let monitor = NWPathMonitor()
    private let monitorQueue = DispatchQueue(label: "NetworkMonitor", qos: .utility)
    
    public var isConnected: Bool = false
    public var connectionType: ConnectionType = .unknown
    public var onNetworkChange: ((Bool) -> Void)?
    
    private var isMonitoring = false
    
    public enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        
        public var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            }
        }
    }
    
    private init() {
        setupMonitor()
    }
    
    deinit {
        stopMonitoring()
    }
    
    public func startMonitoring() {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        monitor.start(queue: monitorQueue)
    }
    
    public func stopMonitoring() {
        guard isMonitoring else { return }
        
        isMonitoring = false
        monitor.cancel()
    }
    
    private func setupMonitor() {
        monitor.pathUpdateHandler = { [weak self] path in
            let wasConnected = self?.isConnected ?? false
            let isNowConnected = path.status == .satisfied
            
            Task { @MainActor in
                self?.isConnected = isNowConnected
                self?.connectionType = self?.getConnectionType(from: path) ?? .unknown
                
                // Notify about network changes
                if wasConnected != isNowConnected {
                    self?.onNetworkChange?(isNowConnected)
                }
            }
        }
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .ethernet
        } else {
            return .unknown
        }
    }
}

// MARK: - Network Quality Assessment

extension NetworkMonitor {
    public var networkQuality: NetworkQuality {
        guard isConnected else { return .none }
        
        switch connectionType {
        case .wifi, .ethernet:
            return .good
        case .cellular:
            return .fair
        case .unknown:
            return .poor
        }
    }
    
    public enum NetworkQuality {
        case none
        case poor
        case fair
        case good
        
        public var displayName: String {
            switch self {
            case .none: return "No Connection"
            case .poor: return "Poor"
            case .fair: return "Fair"
            case .good: return "Good"
            }
        }
        
        public var shouldAllowLargeSync: Bool {
            switch self {
            case .none, .poor:
                return false
            case .fair, .good:
                return true
            }
        }
    }
}