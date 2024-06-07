import Foundation
import Combine
import Security

class CertificateService: ObservableObject {
    @Published var certificateExists: Bool = false
    @Published var certificateCreationDate: Date?
    
    let certificateURL: URL
    let pemURL: URL
    private var opensslPath: String = "/usr/local/bin/openssl"
    var opensslInstaller: OpenSSLInstaller
    
    init(opensslInstaller: OpenSSLInstaller = OpenSSLInstaller()) {
        self.opensslInstaller = opensslInstaller
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            fatalError("Could not find document directory")
        }
        
        self.certificateURL = documentDirectory.appendingPathComponent("certificate.crt")
        self.pemURL = documentDirectory.appendingPathComponent("privateKey.pem")
        
        setup()
        checkCertificateExists()
    }
    
    func setup() {
        print("Setting up OpenSSL path...")
        
        if let opensslPath = findOpenSSLPath(), !opensslPath.isEmpty {
            self.opensslPath = opensslPath
            print("OpenSSL found at path: \(self.opensslPath)")
        } else {
            print("OpenSSL not found in standard locations.")
            promptForOpenSSLPath()
        }
    }
    
    private func findOpenSSLPath() -> String? {
        do {
            let homebrewPrefix = try shell("brew --prefix openssl@3")
            print("Homebrew prefix for OpenSSL: \(homebrewPrefix)")
            if !homebrewPrefix.isEmpty {
                return homebrewPrefix.trimmingCharacters(in: .whitespacesAndNewlines) + "/bin/openssl"
            }
        } catch {
            print("Error finding OpenSSL path with Homebrew: \(error)")
        }
        
        let possiblePaths = [
            "/usr/local/bin/openssl",
            "/usr/bin/openssl",
            "/opt/homebrew/bin/openssl",
            "/opt/local/bin/openssl",
            "/opt/local/sbin/openssl",
            "/usr/local/sbin/openssl",
            "/usr/sbin/openssl"
        ]
        
        for path in possiblePaths {
            if FileManager.default.fileExists(atPath: path) {
                print("OpenSSL found at system path: \(path)")
                return path
            }
        }
        
        return nil
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
        DispatchQueue.global(qos: .background).async {
            do {
                print("Starting certificate generation...")
                
                // Check if OpenSSL exists at the specified path
                guard FileManager.default.fileExists(atPath: self.opensslPath) else {
                    print("OpenSSL not found. Please install OpenSSL via Homebrew.")
                    return
                }
                
                // Generate private key
                let privateKeyProcess = Process()
                privateKeyProcess.executableURL = URL(fileURLWithPath: self.opensslPath)
                privateKeyProcess.arguments = ["genpkey", "-algorithm", "RSA", "-out", self.pemURL.path, "-pkeyopt", "rsa_keygen_bits:2048"]
                
                try privateKeyProcess.run()
                privateKeyProcess.waitUntilExit()
                
                if privateKeyProcess.terminationStatus != 0 {
                    print("Failed to create private key")
                    return
                }
                
                print("Private key written to \(self.pemURL.path)")
                
                // Generate certificate
                let certProcess = Process()
                certProcess.executableURL = URL(fileURLWithPath: self.opensslPath)
                certProcess.arguments = ["req", "-x509", "-new", "-nodes", "-key", self.pemURL.path, "-sha256", "-days", "365", "-out", self.certificateURL.path, "-subj", "/CN=Test/O=TestOrg/C=US"]
                
                try certProcess.run()
                certProcess.waitUntilExit()
                
                if certProcess.terminationStatus != 0 {
                    print("Failed to create certificate")
                    return
                }
                
                print("Certificate written to \(self.certificateURL.path)")
                
                DispatchQueue.main.async {
                    self.certificateExists = true
                    self.certificateCreationDate = Date()
                    print("Certificate generation completed.")
                }
            } catch {
                print("Error generating certificate: \(error)")
            }
        }
    }
    
    private func shell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        
        // Check if zsh exists, otherwise use bash
        if FileManager.default.fileExists(atPath: "/bin/zsh") {
            task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        } else {
            task.executableURL = URL(fileURLWithPath: "/bin/bash")
        }
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
    private func promptForOpenSSLPath() {
        // Implementation to prompt the user to provide the OpenSSL path
        print("Please provide the path to your OpenSSL installation.")
        // This can be implemented using a dialog or input field in the UI.
    }
}
