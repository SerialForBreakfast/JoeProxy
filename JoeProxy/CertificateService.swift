import Foundation
import Combine
import Security

enum CertificateConfiguration {
    case v3CA
    case minimal
}

class CertificateService: ObservableObject {
    @Published var certificateExists: Bool = false
    @Published var certificateCreationDate: Date?

    let certificateURL: URL
    let pemURL: URL
    var opensslPath: String = "/usr/bin/openssl"
    var opensslInstaller: OpenSSLInstaller
    let configuration: CertificateConfiguration = .minimal

    private let v3CaConfig: String = """
    [ v3_ca ]
    subjectKeyIdentifier=hash
    authorityKeyIdentifier=keyid:always,issuer
    basicConstraints = CA:true
    """

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

    func generateCertificate(commonName: String? = "Default Name", organization: String? = "Default Organization", organizationalUnit: String? = "Default OU", country: String? = "US", state: String? = "Default State", locality: String? = "Default Locality", keySize: Int = 2048, validityDays: Int = 365, completion: (() -> Void)?) {
        DispatchQueue.global(qos: .background).async { [weak self] in
            guard let self = self else { return }
            self.log("Using OpensslPath \(self.opensslPath). Starting certificate generation...")

            guard FileManager.default.fileExists(atPath: self.opensslPath) else {
                self.log("OpenSSL not found at path \(self.opensslPath). Please install OpenSSL.")
                return
            }

            let privateKeyProcess = Process()
            privateKeyProcess.executableURL = URL(fileURLWithPath: self.opensslPath)
            privateKeyProcess.arguments = ["genpkey", "-algorithm", "RSA", "-out", self.pemURL.path, "-pkeyopt", "rsa_keygen_bits:\(keySize)"]

            let privateKeyResult = self.runProcess(process: privateKeyProcess)
            guard privateKeyResult.success else {
                self.log("Failed to create private key: \(privateKeyResult.message)")
                return
            }

            self.log("Private key written to \(self.pemURL.path)")

            let certProcess = Process()
            certProcess.executableURL = URL(fileURLWithPath: self.opensslPath)
            var certArguments: [String] = [
                "req", "-x509", "-new", "-nodes", "-key", self.pemURL.path,
                "-sha256", "-days", "\(validityDays)", "-out", self.certificateURL.path,
                "-subj", "/CN=\(commonName!)/O=\(organization!)/OU=\(organizationalUnit!)/C=\(country!)/ST=\(state!)/L=\(locality!)"
            ]
            
            switch self.configuration {
            case .v3CA:
                let configFilePath = self.createTempConfigFile()
                certArguments.append(contentsOf: ["-extensions", "v3_ca", "-config", configFilePath])
            case .minimal:
                break
            }

            certProcess.arguments = certArguments

            let certResult = self.runProcess(process: certProcess)
            guard certResult.success else {
                self.log("Failed to create certificate: \(certResult.message)")
                return
            }

            self.log("Certificate written to \(self.certificateURL.path)")

            DispatchQueue.main.async {
                self.certificateExists = true
                self.certificateCreationDate = Date()
                self.log("Certificate generation completed.")
                completion?()
            }
        }
    }

    private func runProcess(process: Process) -> (success: Bool, message: String) {
        do {
            try process.run()
            process.waitUntilExit()
            return (process.terminationStatus == 0, "Process terminated with status \(process.terminationStatus)")
        } catch {
            return (false, "Failed to run process: \(error)")
        }
    }

    private func log(_ message: String) {
        // Implement logging mechanism here
        print(message)
    }

    private func createTempConfigFile() -> String {
        let tempDir = FileManager.default.temporaryDirectory
        let configFile = tempDir.appendingPathComponent("openssl.cnf")
        
        do {
            try v3CaConfig.write(to: configFile, atomically: true, encoding: .utf8)
        } catch {
            print("Failed to write OpenSSL config file: \(error)")
        }
        
        return configFile.path
    }
}

