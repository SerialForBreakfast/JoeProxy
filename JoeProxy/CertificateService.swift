import Foundation
import Combine
import Security
import AppKit

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
        
        print("Document directory: \(documentDirectory)")
        print("Certificate URL: \(certificateURL)")
        print("PEM URL: \(pemURL)")

        setup()
        checkCertificateExists()
    }
    
    func setup() {
        if let opensslPath = findOpenSSLPath() {
            self.opensslPath = opensslPath
            print("OpenSSL found at path: \(self.opensslPath)")
        } else {
            print("OpenSSL not found. Please install OpenSSL via Homebrew.")
        }
    }
    
    func findOpenSSLPath() -> String? {
        // Prioritize finding OpenSSL using 'which openssl'
        if let opensslPath = try? shell("which openssl"), !opensslPath.isEmpty {
            return opensslPath.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        
        let paths = [
            "/usr/local/bin/openssl",
            "/usr/bin/openssl",
            "/opt/homebrew/bin/openssl",
            "/opt/local/bin/openssl"
        ]
        
        for path in paths {
            if FileManager.default.fileExists(atPath: path) {
                return path
            }
        }
        
        if let homebrewPath = try? shell("brew --prefix openssl@3"), !homebrewPath.isEmpty {
            let trimmedPath = homebrewPath.trimmingCharacters(in: .whitespacesAndNewlines) + "/bin/openssl"
            if FileManager.default.fileExists(atPath: trimmedPath) {
                return trimmedPath
            }
        }
        
        return nil
    }
    
    func checkCertificateExists() {
        let fileManager = FileManager.default
        print("Checking if certificate and PEM files exist...")
        if fileManager.fileExists(atPath: certificateURL.path) && fileManager.fileExists(atPath: pemURL.path) {
            print("Certificate and PEM files found.")
            self.certificateExists = true
            if let attributes = try? fileManager.attributesOfItem(atPath: certificateURL.path),
               let creationDate = attributes[.creationDate] as? Date {
                self.certificateCreationDate = creationDate
            }
        } else {
            print("Certificate and/or PEM files not found.")
            self.certificateExists = false
            self.certificateCreationDate = nil
        }
    }
    
    func generateCertificate() {
        DispatchQueue.global(qos: .background).async {
            do {
                print("Starting certificate generation...")
                
                guard FileManager.default.fileExists(atPath: self.opensslPath) else {
                    print("OpenSSL not found. Please install OpenSSL via Homebrew.")
                    return
                }
                
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
        task.executableURL = self.shellExecutableURL()
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)!
        
        return output
    }
    
    private func shellExecutableURL() -> URL {
        if FileManager.default.fileExists(atPath: "/bin/zsh") {
            return URL(fileURLWithPath: "/bin/zsh")
        } else {
            return URL(fileURLWithPath: "/bin/bash")
        }
    }
    
    func openCertificateDirectory() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else {
            fatalError("Could not find document directory")
        }
        
        NSWorkspace.shared.open(documentDirectory)
    }
}
