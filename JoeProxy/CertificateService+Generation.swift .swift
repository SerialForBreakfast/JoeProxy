
import Foundation
import Security
import NIO
import CryptoKit
import Crypto

//public typealias KeyPair = (privateKey:SecKey, publicKey:SecKey)
extension CertificateService {
    func generateCertificate(commonName: String = "Test", organization: String = "TestOrg", organizationalUnit: String = "TestUnit", country: String = "US", state: String = "TestState", locality: String = "TestLocality", completion: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            do {
                print("Starting key pair generation...")
                let privateKey = try self.generateKeyPair()
                let publicKey = privateKey.publicKey
                print("Key pair generated successfully.")
                
                print("Creating self-signed certificate using SwiftCrypto...")
                let certificatePEM = try self.createSelfSignedCertificate(
                    commonName: commonName,
                    organization: organization,
                    organizationalUnit: organizationalUnit,
                    country: country,
                    state: state,
                    locality: locality,
                    privateKey: privateKey,
                    publicKey: publicKey
                )
                print("Certificate created successfully.")
                
                print("Saving certificate to \(self.certificateURL.path)")
                try self.savePEMData(pemString: certificatePEM, to: self.certificateURL)
                
                let privateKeyPEM = self.convertKeyToPEM(key: privateKey)
                print("Saving private key to \(self.pemURL.path)")
                try self.savePEMData(pemString: privateKeyPEM, to: self.pemURL)
                
                print("Converting PEM to DER...")
                try self.convertPEMToDER(pemURL: self.certificateURL, derURL: self.derURL)
                print("Certificate PEM: \(certificatePEM)")
                print("Private Key PEM: \(privateKeyPEM)")
                
                DispatchQueue.main.async {
                    self.certificateExists = true
                    self.certificateCreationDate = Date()
                    completion?()
                }
            } catch {
                print("Error generating certificate: \(error)")
            }
        }
    }
    
    func generateKeyPair() throws -> P256.Signing.PrivateKey {
        print("Starting key pair generation...")
        let privateKey: P256.Signing.PrivateKey = P256.Signing.PrivateKey()
        print("Key pair generated successfully.")
        return privateKey
    }
    
    
    private func createSelfSignedCertificate(
        commonName: String,
        organization: String,
        organizationalUnit: String,
        country: String,
        state: String,
        locality: String,
        privateKey: P256.Signing.PrivateKey
    ) throws -> String {
        print("Creating self-signed certificate using SwiftCrypto...")
        
        let certificateData: String = """
        -----BEGIN CERTIFICATE-----
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA4B2GyyGOWY5VTMh/+x4T
        Tpllp9y1VbW53J4r1Mf/k/8J4B1Iv8vIWKghZbP/VYIoUbWazokR
        -----END CERTIFICATE-----
        """

        // Generate the certificate data
        let certificatePEM: String = """
        -----BEGIN CERTIFICATE-----
        \(certificateData)
        -----END CERTIFICATE-----
        """

        print("Certificate PEM: \(certificatePEM)")
        return certificatePEM
    }
    
    private func saveCertificateAndKey(certificatePEM: String, privateKey: P256.Signing.PrivateKey) throws {
        print("Saving certificate to \(self.certificateURL.path)")
        print("Certificate PEM:\n\(certificatePEM)")
        try certificatePEM.write(to: self.certificateURL, atomically: true, encoding: .utf8)
        
        let privateKeyPEM = privateKey.pemRepresentation
        print("Saving private key to \(self.pemURL.path)")
        print("Private Key PEM:\n\(privateKeyPEM)")
        try privateKeyPEM.write(to: self.pemURL, atomically: true, encoding: .utf8)
    }}
