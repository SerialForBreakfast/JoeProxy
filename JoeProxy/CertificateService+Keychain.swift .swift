//
//  CertificateService+Keychain.swift .swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import Foundation
import Security

extension CertificateService {
    func addCertificateToKeychain(certificateURL: URL) throws {
        let derData: Data = try Data(contentsOf: certificateURL)
        guard let certificate: SecCertificate = SecCertificateCreateWithData(nil, derData as CFData) else {
            throw NSError(domain: "Keychain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create SecCertificate"])
        }

        let status: OSStatus = SecItemAdd([
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certificate
        ] as CFDictionary, nil)

        guard status == errSecSuccess else {
            throw NSError(domain: "Keychain", code: Int(status), userInfo: [NSLocalizedDescriptionKey: "Failed to add certificate to keychain"])
        }
    }
}
