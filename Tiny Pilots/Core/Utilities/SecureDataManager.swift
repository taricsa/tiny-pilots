import Foundation
import Security
import CryptoKit

/// Protocol for secure data storage operations
protocol SecureDataManagerProtocol {
    func storeSecureData<T: Codable>(_ data: T, forKey key: String) throws
    func retrieveSecureData<T: Codable>(_ type: T.Type, forKey key: String) throws -> T?
    func deleteSecureData(forKey key: String) throws
    func encryptData<T: Codable>(_ data: T) throws -> Data
    func decryptData<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T
    func validateDataIntegrity<T: Codable>(_ data: T, expectedHash: String) -> Bool
    func generateDataHash<T: Codable>(_ data: T) throws -> String
}

/// Secure data manager for handling encrypted storage and keychain operations
class SecureDataManager: SecureDataManagerProtocol {
    static let shared = SecureDataManager()
    
    private let keychainService = "com.tinypilots.secure"
    private let encryptionKeyTag = "com.tinypilots.encryption.key"
    private let logger = Logger.shared
    
    private init() {
        // Ensure encryption key exists
        do {
            try ensureEncryptionKeyExists()
        } catch {
            logger.critical("Failed to initialize encryption key", error: error, category: .security)
        }
    }
    
    // MARK: - Public Interface
    
    /// Store data securely in keychain with encryption
    func storeSecureData<T: Codable>(_ data: T, forKey key: String) throws {
        logger.debug("Storing secure data for key: \(key)", category: .security)
        
        let encryptedData = try encryptData(data)
        try storeInKeychain(encryptedData, forKey: key)
        
        logger.info("Successfully stored secure data for key: \(key)", category: .security)
    }
    
    /// Retrieve and decrypt data from keychain
    func retrieveSecureData<T: Codable>(_ type: T.Type, forKey key: String) throws -> T? {
        logger.debug("Retrieving secure data for key: \(key)", category: .security)
        
        guard let encryptedData = try retrieveFromKeychain(forKey: key) else {
            logger.debug("No data found for key: \(key)", category: .security)
            return nil
        }
        
        let decryptedData = try decryptData(encryptedData, as: type)
        logger.info("Successfully retrieved secure data for key: \(key)", category: .security)
        
        return decryptedData
    }
    
    /// Delete secure data from keychain
    func deleteSecureData(forKey key: String) throws {
        logger.debug("Deleting secure data for key: \(key)", category: .security)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw SecureDataError.keychainError(status)
        }
        
        logger.info("Successfully deleted secure data for key: \(key)", category: .security)
    }
    
    /// Encrypt data using AES-GCM
    func encryptData<T: Codable>(_ data: T) throws -> Data {
        let jsonData = try JSONEncoder().encode(data)
        guard let key = try getEncryptionKey() else {
            throw SecureDataError.invalidKeyData
        }
        
        let sealedBox = try AES.GCM.seal(jsonData, using: key)
        
        guard let encryptedData = sealedBox.combined else {
            throw SecureDataError.encryptionFailed
        }
        
        return encryptedData
    }
    
    /// Decrypt data using AES-GCM
    func decryptData<T: Codable>(_ encryptedData: Data, as type: T.Type) throws -> T {
        guard let key = try getEncryptionKey() else {
            throw SecureDataError.invalidKeyData
        }
        
        let sealedBox = try AES.GCM.SealedBox(combined: encryptedData)
        let decryptedData = try AES.GCM.open(sealedBox, using: key)
        
        return try JSONDecoder().decode(type, from: decryptedData)
    }
    
    /// Validate data integrity using SHA-256 hash
    func validateDataIntegrity<T: Codable>(_ data: T, expectedHash: String) -> Bool {
        do {
            let actualHash = try generateDataHash(data)
            return actualHash == expectedHash
        } catch {
            logger.error("Failed to validate data integrity", error: error, category: .security)
            return false
        }
    }
    
    /// Generate SHA-256 hash for data integrity validation
    func generateDataHash<T: Codable>(_ data: T) throws -> String {
        let jsonData = try JSONEncoder().encode(data)
        let hash = SHA256.hash(data: jsonData)
        return hash.compactMap { String(format: "%02x", $0) }.joined()
    }
    
    // MARK: - Private Implementation
    
    /// Ensure encryption key exists in keychain, create if needed
    private func ensureEncryptionKeyExists() throws {
        // Check if key already exists
        if try getEncryptionKey() != nil {
            return
        }
        
        // Generate new encryption key
        let key = SymmetricKey(size: .bits256)
        let keyData = key.withUnsafeBytes { Data($0) }
        
        // Store in keychain
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw SecureDataError.keychainError(status)
        }
        
        logger.info("Created new encryption key", category: .security)
    }
    
    /// Retrieve encryption key from keychain
    private func getEncryptionKey() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: encryptionKeyTag,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw SecureDataError.keychainError(status)
        }
        
        guard let keyData = result as? Data else {
            throw SecureDataError.invalidKeyData
        }
        
        return SymmetricKey(data: keyData)
    }
    
    /// Store data in keychain
    private func storeInKeychain(_ data: Data, forKey key: String) throws {
        // Delete existing item first
        try? deleteSecureData(forKey: key)
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw SecureDataError.keychainError(status)
        }
    }
    
    /// Retrieve data from keychain
    private func retrieveFromKeychain(forKey key: String) throws -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecItemNotFound {
            return nil
        }
        
        if status != errSecSuccess {
            throw SecureDataError.keychainError(status)
        }
        
        return result as? Data
    }
}

/// Errors related to secure data operations
enum SecureDataError: Error, LocalizedError {
    case keychainError(OSStatus)
    case encryptionFailed
    case decryptionFailed
    case invalidKeyData
    case dataCorrupted
    case hashMismatch
    
    var errorDescription: String? {
        switch self {
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidKeyData:
            return "Invalid encryption key data"
        case .dataCorrupted:
            return "Data appears to be corrupted"
        case .hashMismatch:
            return "Data integrity check failed"
        }
    }
}