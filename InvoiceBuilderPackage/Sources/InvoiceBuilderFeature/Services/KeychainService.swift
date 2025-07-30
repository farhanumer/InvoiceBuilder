import Foundation
import Security

public enum KeychainError: Error {
    case duplicateItem
    case itemNotFound
    case invalidData
    case unexpectedError(OSStatus)
}

@Observable
public final class KeychainService: @unchecked Sendable {
    public static let shared = KeychainService()
    
    private let serviceName: String
    
    private init(serviceName: String = Bundle.main.bundleIdentifier ?? "com.invoicebuilder.app") {
        self.serviceName = serviceName
    }
    
    public func save(data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecDuplicateItem {
            try update(data: data, for: key)
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedError(status)
        }
    }
    
    public func load(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key,
            kSecReturnData as String: kCFBooleanTrue!,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecItemNotFound {
            throw KeychainError.itemNotFound
        } else if status != errSecSuccess {
            throw KeychainError.unexpectedError(status)
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    public func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw KeychainError.unexpectedError(status)
        }
    }
    
    private func update(data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecAttrAccount as String: key
        ]
        
        let attributes: [String: Any] = [
            kSecValueData as String: data
        ]
        
        let status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        
        if status != errSecSuccess {
            throw KeychainError.unexpectedError(status)
        }
    }
}