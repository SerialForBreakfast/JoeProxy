import Foundation
import Combine
import Security
import Crypto

class CertificateService: ObservableObject {
    @Published var certificateExists: Bool = false
    @Published var certificateCreationDate: Date?
    
    let certificateURL: URL
    let pemURL: URL
    let derURL: URL
    
    init(debug: Bool = false) {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            fatalError("Could not find document directory")
        }
        
        let certDirectory = debug ? documentDirectory.appendingPathComponent("debugCerts") : documentDirectory
        if debug {
            try? fileManager.createDirectory(at: certDirectory, withIntermediateDirectories: true, attributes: nil)
        }
        
        self.certificateURL = certDirectory.appendingPathComponent("certificate.crt")
        self.pemURL = certDirectory.appendingPathComponent("privateKey.pem")
        self.derURL = certDirectory.appendingPathComponent("privateKey.der")
        
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
}
