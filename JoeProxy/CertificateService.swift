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

    init(opensslInstaller: OpenSSLInstaller = OpenSSLInstaller(), debug: Bool = false) {
        self.opensslInstaller = opensslInstaller
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
            do {
                guard let self else { return }
                print("Using OpensslPath \(self.opensslPath). Starting certificate generation...")

                guard FileManager.default.fileExists(atPath: self.opensslPath) else {
                    print("OpenSSL not found at path \(self.opensslPath). Please install OpenSSL via Homebrew.")
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
}
