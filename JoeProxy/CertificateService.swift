import Foundation
import Combine
import Security
import NIO
import NIOSSL

class CertificateService: ObservableObject {
    @Published var certificateExists: Bool = false
    @Published var certificateCreationDate: Date?

    let certificateURL: URL
    let pemURL: URL
    private var opensslPath: String = "/usr/bin/openssl"
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
        if let path = OpenSSLInstaller.findOpenSSLPath() {
            self.opensslPath = path
        } else {
            print("OpenSSL not found. Please install OpenSSL via Homebrew.")
        }
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
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self else { return }
            do {
                print("Using OpenSSL at \(self.opensslPath). Starting certificate generation...")

                guard FileManager.default.fileExists(atPath: self.opensslPath) else {
                    print("OpenSSL not found at path \(self.opensslPath). Please install OpenSSL via Homebrew.")
                    return
                }

                try self.createPrivateKey()
                try self.createCertificate()

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

    private func createPrivateKey() throws {
        let privateKeyProcess = Process()
        privateKeyProcess.executableURL = URL(fileURLWithPath: opensslPath)
        privateKeyProcess.arguments = ["genpkey", "-algorithm", "RSA", "-out", pemURL.path, "-pkeyopt", "rsa_keygen_bits:2048"]

        try privateKeyProcess.run()
        privateKeyProcess.waitUntilExit()

        if privateKeyProcess.terminationStatus != 0 {
            throw NSError(domain: "com.example.JoeProxy", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create private key"])
        }

        print("Private key written to \(pemURL.path)")
    }

    private func createCertificate() throws {
        let certProcess = Process()
        certProcess.executableURL = URL(fileURLWithPath: opensslPath)
        certProcess.arguments = ["req", "-x509", "-new", "-nodes", "-key", pemURL.path, "-sha256", "-days", "365", "-out", certificateURL.path, "-subj", "/CN=Test/O=TestOrg/C=US"]

        try certProcess.run()
        certProcess.waitUntilExit()

        if certProcess.terminationStatus != 0 {
            throw NSError(domain: "com.example.JoeProxy", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to create certificate"])
        }

        print("Certificate written to \(certificateURL.path)")
    }

    func loadCertificate() throws -> NIOSSLContext {
        guard certificateExists else {
            throw NSError(domain: "com.example.JoeProxy", code: 1, userInfo: [NSLocalizedDescriptionKey: "Certificate not found"])
        }

        let certChain = try NIOSSLCertificate.fromPEMFile(certificateURL.path)
        let key = try NIOSSLPrivateKey(file: pemURL.path, format: .pem)
        let tlsConfig = TLSConfiguration.makeServerConfiguration(certificateChain: certChain.map { .certificate($0) }, privateKey: .privateKey(key))
        return try NIOSSLContext(configuration: tlsConfig)
    }
}
