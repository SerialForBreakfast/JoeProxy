//
//  CertificateService+Conversion.swift .swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import Foundation

extension CertificateService {
    func convertKeyToPEM(key: SecKey) -> String {
        guard let keyData = SecKeyCopyExternalRepresentation(key, nil) as Data? else {
            return ""
        }
        let base64Key = keyData.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        let pemKey = """
        -----BEGIN PRIVATE KEY-----
        \(base64Key)
        -----END PRIVATE KEY-----
        """
        return pemKey
    }
    
    func convertCertificateToPEM(certificate: SecCertificate) -> String {
        let certificateData = SecCertificateCopyData(certificate) as Data
        let base64Cert = certificateData.base64EncodedString(options: [.lineLength64Characters, .endLineWithLineFeed])
        let pemCert = """
        -----BEGIN CERTIFICATE-----
        \(base64Cert)
        -----END CERTIFICATE-----
        """
        return pemCert
    }
    func convertCertificateToDER(certificate: SecCertificate) throws -> Data {
        let certData = SecCertificateCopyData(certificate) as Data
        return certData
    }
    
    func addCertificateToKeychain(certificateData: Data) throws {
        guard let cert = SecCertificateCreateWithData(nil, certificateData as CFData) else {
            throw NSError(domain: "CertificateService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create certificate from DER data"])
        }
        
        let addQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: cert,
            kSecAttrLabel as String: "JoeProxy Certificate"
        ]
        
        let status = SecItemAdd(addQuery as CFDictionary, nil)
        if status != errSecSuccess {
            throw NSError(domain: "CertificateService", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to add certificate to keychain: \(status)"])
        }
    }
    private func convertPEMToDER(pemString: String) throws -> Data {
        print("Converting PEM to DER...")
        let lines: [Substring] = pemString.split(separator: "\n")
        let base64String: String = lines.dropFirst().dropLast().joined()
        print("PEM String: \(pemString)")
        print("Base64 String: \(base64String)")

        guard let derData: Data = Data(base64Encoded: base64String) else {
            print("Invalid base64 data")
            throw NSError(domain: "PEMConversion", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data"])
        }
        return derData
    }
    
//    func convertPEMToDER(pemURL: URL, derURL: URL) throws {
//        let pemData: Data = try Data(contentsOf: pemURL)
//        guard let pemString: String = String(data: pemData, encoding: .utf8) else {
//            throw NSError(domain: "PEMConversion", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid PEM data"])
//        }
//        
//        print("PEM String:\n\(pemString)")
//        
//        let lines: [String.SubSequence] = pemString.split(separator: "\n")
//        let base64String: String = lines.dropFirst().dropLast().joined()
//        print("Base64 String: \(base64String)")
//        
//        guard let derData: Data = Data(base64Encoded: base64String) else {
//            throw NSError(domain: "PEMConversion", code: 2, userInfo: [NSLocalizedDescriptionKey: "Invalid base64 data"])
//        }
//        
//        try derData.write(to: derURL)
//    }
}
