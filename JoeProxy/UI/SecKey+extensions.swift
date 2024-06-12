////
////  SecKey+extensions.swift
////  JoeProxyTests
////
////  Created by Joseph McCraw on 6/11/24.
////
//
//import Foundation
//import Security
//
//public typealias KeyPair = (privateKey:SecKey, publicKey:SecKey)
//
//extension SecKey {
//
//    /**
//     * Generates an RSA private-public key pair. Wraps `SecKeyGeneratePair()`.
//     *
//     * - parameter ofSize: the size of the keys in bits
//     * - returns: The generated key pair.
//     * - throws: A `SecKeyError` when something went wrong.
//     */
//    public static func generateKeyPair(ofSize bits:UInt) throws -> KeyPair {
//        let pubKeyAttrs = [ kSecAttrIsPermanent as String: true ]
//        let privKeyAttrs = [ kSecAttrIsPermanent as String: true ]
//        let params: NSDictionary = [ kSecAttrKeyType as String : kSecAttrKeyTypeRSA as String,
//                       kSecAttrKeySizeInBits as String : bits,
//                       kSecPublicKeyAttrs as String : pubKeyAttrs,
//                       kSecPrivateKeyAttrs as String : privKeyAttrs ]
//        var pubKey: SecKey?
//        var privKey: SecKey?
//        let status = SecKeyGeneratePair(params, &pubKey, &privKey)
//        guard status == errSecSuccess else {
//            throw NSError()
//        }
//        guard let pub = pubKey, let priv = privKey else {
//            throw NSError()
//        }
//
//        try changeKeyTag(priv)
//        try changeKeyTag(pub)
//
//        return (priv, pub)
//    }
//
//    static fileprivate func changeKeyTag(_ key: SecKey) throws {
//        let query = [kSecValueRef as String: key]
//        guard let keyTag = key.keychainTag else {
//            throw NSError()
//        }
//        let attrsToUpdate = [kSecAttrApplicationTag as String: keyTag]
//        let status = SecItemUpdate(query as CFDictionary, attrsToUpdate as CFDictionary)
//
//        guard status == errSecSuccess else {
//            throw NSError()
//        }
//    }
//
//    /**
//     * The block size of the key. Wraps `SecKeyGetBlockSize()`.
//     */
//    public var blockSize: Int {
//        return SecKeyGetBlockSize(self)
//    }
//}
//
//import Foundation
//import Security
//import IDZSwiftCommonCrypto
//
//extension SecKey {
//    /**
//     * Returns the tag that was used to store the key in the keychain.
//     * You can use this tag to retrieve the key using `loadFromKeychain(tag:)`
//     *
//     * - returns: the tag of the key
//     */
//    public var keychainTag: String? {
//        guard let keyData = self.keyData else {
//            return nil
//        }
//        return SecKey.keychainTag(forKeyData: keyData)
//    }
//
//    /**
//     * Returns the tag of a key that is represented by the given key data.
//     * Normally you should prefer using the instance property `keychainTag`
//     * instead.
//     */
//    static public func keychainTag(forKeyData data: [UInt8]) -> String {
//        let sha1 = Digest(algorithm: .sha1)
//        _ = sha1.update(buffer: data, byteCount: data.count)
//        let digest = sha1.final()
//        return digest.hexString()
//    }
//
//    /**
//     * Loads a key from the keychain given its tag. The tag is the string returned by
//     * the property `keychainTag`.
//     *
//     * - parameter tag: the tag as returned by `keychainTag`
//     * - returns: the retrieved key, if found
//     */
//    static public func loadFromKeychain(tag: String) -> SecKey? {
//        let query: [String:AnyObject] = [
//                kSecClass as String: kSecClassKey,
//                kSecAttrApplicationTag as String: tag as AnyObject,
//                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//                kSecReturnRef as String: true as AnyObject
//        ]
//
//        var result: AnyObject?
//        let status = SecItemCopyMatching(query as CFDictionary, &result)
//        guard let resultObject = result, status == errSecSuccess
//                  && CFGetTypeID(resultObject) == SecKeyGetTypeID() else {
//            return nil
//        }
//        return (resultObject as! SecKey)
//    }
//}
//// Copyright (c) 2016 Stefan van den Oord. All rights reserved.
//import Foundation
//
//extension Sequence where Iterator.Element == UInt8 {
//    /**
//     * Creates a string representation of a byte array (`[UInt8]`) by concatenating
//     * the hexadecimal representation of all bytes. The string _does not_ include
//     * the prefix '0x' that is commonly used to indicate hexadecimal representations.
//     *
//     * - returns: the hexadecimal representation of the byte array
//     */
//    public func hexString() -> String {
//        return self.reduce("", { $0 + String(format: "%02x", $1)})
//    }
//}
//
//extension String {
//    /**
//     * Converts a string containing the hexadecimal representation of a byte
//     * to a byte array. The string must not contain anything else. It may
//     * optionally start with the prefix '0x'. Conversion is case insensitive.
//     *
//     * - returns: the parsed byte array, or nil if parsing failed
//     */
//    public func hexByteArray() -> [UInt8]? {
//        guard self.count % 2 == 0 else {
//            return nil
//        }
//        let stringToConvert: String
//        let prefixRange = self.range(of: "0x")
//        if let r = prefixRange, r.lowerBound == self.startIndex && r.upperBound != r.lowerBound {
//            stringToConvert = String(self[r.upperBound...])
//        }
//        else {
//            stringToConvert = self
//        }
//        return stringToByteArray(stringToConvert)
//    }
//}
//
//private func stringToByteArray(_ string: String) -> [UInt8]? {
//    var result = [UInt8]()
//    for byteIndex in 0 ..< string.count/2 {
//        let start = string.index(string.startIndex, offsetBy: byteIndex*2)
//        let end = string.index(start, offsetBy: 2)
//        let byteString = string[start ..< end]
//        guard let byte = scanHexByte(String(byteString)) else {
//            return nil
//        }
//        result.append(byte)
//    }
//    return result
//}
//
//private func scanHexByte(_ byteString: String) -> UInt8? {
//    var scanned: UInt64 = 0
//    let scanner = Scanner(string: byteString)
//    guard scanner.scanHexInt64(&scanned) && scanner.isAtEnd else {
//        return nil
//    }
//    return UInt8(scanned)
//}
//
//extension SecKey {
//
//    /**
//     * Provides the raw key data. Wraps `SecItemCopyMatching()`. Only works if the key is
//     * available in the keychain. One common way of using this data is to derive a hash
//     * of the key, which then can be used for other purposes.
//     *
//     * The format of this data is not documented. There's been some reverse-engineering:
//     * https://devforums.apple.com/message/32089#32089
//     * Apparently it is a DER-formatted sequence of a modulus followed by an exponent.
//     * This can be converted to OpenSSL format by wrapping it in some additional DER goop.
//     *
//     * - returns: the key's raw data if it could be retrieved from the keychain, or `nil`
//     */
//    public var keyData: [UInt8]? {
//        let query = [ kSecValueRef as String : self, kSecReturnData as String : true ] as [String : Any]
//        var out: AnyObject?
//        guard errSecSuccess == SecItemCopyMatching(query as CFDictionary, &out) else {
//            return nil
//        }
//        guard let data = out as? Data else {
//            return nil
//        }
//
//        var bytes = [UInt8](repeating: 0, count: data.count)
//        (data as NSData).getBytes(&bytes, length:data.count)
//        return bytes
//    }
//
//    /**
//     * Creates a SecKey based on its raw data, as provided by `keyData`. The key is also
//     * imported into the keychain. If the key already existed in the keychain, it will simply
//     * be returned.
//     *
//     * - parameter data: the raw key data as returned by `keyData`
//     * - returns: the key if it was successfully created and imported, or nil
//     */
//    static public func create(withData data: [UInt8]) -> SecKey? {
//        let tag = SecKey.keychainTag(forKeyData: data)
//        let cfData = CFDataCreate(kCFAllocatorDefault, data, data.count)
//
//        let query: Dictionary<String, AnyObject> = [
//                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
//                kSecClass as String: kSecClassKey,
//                kSecAttrApplicationTag as String: tag as AnyObject,
//                kSecValueData as String: cfData!,
//                kSecReturnPersistentRef as String: true as AnyObject]
//
//        var persistentRef: AnyObject?
//        let status = SecItemAdd(query as CFDictionary, &persistentRef)
//        guard status == errSecSuccess || status == errSecDuplicateItem else {
//            return nil
//        }
//
//        return SecKey.loadFromKeychain(tag: tag)
//    }
//}
//
//public extension SecKey {
//
//    /**
//     * Encrypt the given bytes. Requires that this key is a public key. Encryption uses PKCS1 padding.
//     *
//     * - parameter bytes: the content that needs to be encrypted
//     * - returns: the encrypted bytes, or `nil` if the encryption failed.
//     */
//    func encrypt(_ bytes: [UInt8]) -> [UInt8]? {
//        let blockSize = SecKeyGetBlockSize(self)
//
//        // From SecKeyEncrypt:
//        // When PKCS1 padding is performed, the maximum length of data that can be
//        // encrypted is 11 bytes less than the value returned by the SecKeyGetBlockSize
//        // function (secKeyGetBlockSize() - 11)
//        let maxDataLength = blockSize - 11
//
//        var encryptedBytes = [UInt8]()
//
//        let numBlocks = Int(ceil(Float(bytes.count) / Float(maxDataLength)))
//        for i in 0 ..< numBlocks {
//            let start = i * maxDataLength
//            let end = min((i+1) * maxDataLength, bytes.count)
//            let block = Array(bytes[start ..< end])
//
//            var cypherText: [UInt8] = Array(repeating: UInt8(0), count: Int(blockSize))
//            var cypherLength: Int = blockSize
//
//            let resultCode = SecKeyEncrypt(self, SecPadding.PKCS1, block, block.count, &cypherText, &cypherLength)
//            guard resultCode == errSecSuccess else {
//                return nil
//            }
//            encryptedBytes += cypherText[0 ..< cypherLength]
//        }
//        return encryptedBytes
//    }
//
//    /**
//     * Encrypt the given string by encrypting its UTF-8 encoded bytes. Requires that this key is a public key.
//     * Encryption uses PKCS1 padding.
//     *
//     * - parameter utf8Text: the string that needs to be encrypted
//     * - returns: the encrypted bytes, or `nil` if the encryption failed.
//     */
//    func encrypt(_ utf8Text: String) -> [UInt8]? {
//        let plainTextData: [UInt8] = [UInt8](utf8Text.utf8)
//        return encrypt(plainTextData)
//    }
//
//    /**
//     * Decrypts the given bytes. Requires that this key is a private key. Decrypts using PKCS1 padding.
//     *
//     * - parameter cypherText: the data that needs to be decrypted
//     * - returns: the decrypted content, or `nil` if decryption failed
//     */
//    func decrypt(_ cypherText: [UInt8]) -> [UInt8]? {
//        let blockSize = SecKeyGetBlockSize(self)
//
//        var decryptedBytes = [UInt8]()
//
//        let numBlocks = Int(ceil(Float(cypherText.count) / Float(blockSize)))
//        for i in 0 ..< numBlocks {
//            let start = i * blockSize
//            let end = min((i+1)*blockSize, cypherText.count)
//            let block = Array(cypherText[start ..< end])
//
//            var plainTextData: [UInt8] = Array(repeating: UInt8(0), count: Int(blockSize))
//            var plainTextDataLength: Int = blockSize
//            let resultCode = SecKeyDecrypt(self, SecPadding.PKCS1, block, block.count, &plainTextData, &plainTextDataLength)
//            guard resultCode == errSecSuccess else {
//                return nil
//            }
//            decryptedBytes += Array(plainTextData[0 ..< plainTextDataLength])
//        }
//
//        return decryptedBytes
//    }
//
//    /**
//     * Decrypts the given bytes to a string by interpreting the decrypted result as an UTF-8 encoded string.
//     * Requires that this key is a private key. Decrypts using PKCS1 padding.
//     *
//     * - parameter cypherText: the data that needs to be decrypted
//     * - returns: the decrypted UTF-8 string, or `nil` if decryption failed
//     */
//    func decryptUtf8(_ cypherText: [UInt8]) -> String? {
//        guard let plainTextData = decrypt(cypherText) else {
//            return nil
//        }
//        let plainText = NSString(bytes: plainTextData, length: plainTextData.count, encoding: String.Encoding.utf8.rawValue)
//        return plainText as String?
//    }
//
//}
import Foundation
import Crypto

struct SelfSignedCertificate {
    let pemRepresentation: String

    init(
        privateKey: P256.Signing.PrivateKey,
        commonName: String,
        organization: String,
        organizationalUnit: String,
        country: String,
        stateOrProvinceName: String,
        locality: String
    ) throws {
        // Generate the X.509 certificate using SwiftCrypto and the provided details.
        // This is a simplified example and might need adjustments for a production environment.

        let privateKeyPEM: String = privateKey.pemRepresentation
        let publicKeyPEM: String = privateKey.publicKey.pemRepresentation

        let subject: String = "/CN=\(commonName)/O=\(organization)/OU=\(organizationalUnit)/C=\(country)/ST=\(stateOrProvinceName)/L=\(locality)"
        
        // You would normally create the certificate with OpenSSL or similar tools.
        // For this example, we assume the certificate is generated and PEM encoded.
        
        self.pemRepresentation = """
        -----BEGIN CERTIFICATE-----
        // Your certificate data here
        -----END CERTIFICATE-----
        """
    }
}

extension P256.Signing.PrivateKey {
    var pemRepresentation: String {
        // Convert the private key to PEM format.
        // This is a simplified example. Adjust as necessary for your use case.
        return """
        -----BEGIN PRIVATE KEY-----
        \(self.rawRepresentation.base64EncodedString())
        -----END PRIVATE KEY-----
        """
    }
}

extension P256.Signing.PublicKey {
    var pemRepresentation: String {
        // Convert the public key to PEM format.
        // This is a simplified example. Adjust as necessary for your use case.
        return """
        -----BEGIN PUBLIC KEY-----
        \(self.rawRepresentation.base64EncodedString())
        -----END PUBLIC KEY-----
        """
    }
}
