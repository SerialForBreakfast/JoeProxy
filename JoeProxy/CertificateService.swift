import Foundation
import Security

class CertificateService: ObservableObject {
    @Published var certificateExists: Bool = false
    @Published var certificateCreationDate: Date?
    
    private let certificateURL: URL
    private let pemURL: URL
    
    init() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            fatalError("Could not find document directory")
        }
        
        self.certificateURL = documentDirectory.appendingPathComponent("certificate.cert")
        self.pemURL = documentDirectory.appendingPathComponent("privateKey.pem")
        
        checkCertificateExists()
    }
    
    func checkCertificateExists() {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: certificateURL.path) && fileManager.fileExists(atPath: pemURL.path) {
            self.certificateExists = true
            if let attributes = try? fileManager.attributesOfItem(atPath: certificateURL.path),
               let creationDate = attributes[.creationDate] as? Date {
                self.certificateCreationDate = creationDate
            }
        } else {
            self.certificateExists = false
            self.certificateCreationDate = nil
        }
    }
    
    func generateCertificate() {
        do {
            let privateKey = try SecKeyCreateRandomKey([
                kSecAttrKeyType: kSecAttrKeyTypeRSA,
                kSecAttrKeySizeInBits: 2048
            ] as CFDictionary, nil)
            
            let subjectName = "CN=Test, O=TestOrg, C=US"
            let certificateAttributes: [String: Any] = [
                kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                kSecAttrKeySizeInBits as String: 2048,
                kSecAttrIsPermanent as String: true
            ]
            
            guard let privateKey = privateKey else {
                print("Failed to create private key")
                return
            }
            
            var error: Unmanaged<CFError>?
            guard let keyData = SecKeyCopyExternalRepresentation(privateKey, &error) as Data? else {
                print("Failed to copy key data: \(String(describing: error?.takeRetainedValue()))")
                return
            }
            
            try keyData.write(to: pemURL)
            
            guard let certificate = SecCertificateCreateWithData(nil, Data() as CFData) else {
                print("Failed to create certificate")
                return
            }
            
            if let certData = SecCertificateCopyData(certificate) as Data? {
                try certData.write(to: certificateURL)
            }
            
            self.certificateExists = true
            self.certificateCreationDate = Date()
        } catch {
            print("Error generating certificate: \(error)")
        }
    }
}
