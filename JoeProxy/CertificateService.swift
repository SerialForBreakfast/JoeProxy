import Foundation
import Combine
import Security

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

    func generateCertificate(commonName: String? = nil, organization: String? = nil, organizationalUnit: String? = nil, country: String? = nil, state: String? = nil, locality: String? = nil, completion: (() -> Void)?) {
        if certificateExists {
            print("Certificate already exists, created on \(certificateCreationDate!). Overriding...")
            removeExistingCertificate()
        }

        DispatchQueue.global(qos: .background).async { [weak self] in
            do {
                guard let self = self else { return }
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
                certProcess.arguments = ["req", "-x509", "-new", "-nodes", "-key", self.pemURL.path, "-sha256", "-days", "365", "-out", self.certificateURL.path, "-subj", "/CN=\(commonName ?? "Test")/O=\(organization ?? "TestOrg")/OU=\(organizationalUnit ?? "TestUnit")/C=\(country ?? "US")/ST=\(state ?? "TestState")/L=\(locality ?? "TestLocality")"]

                try certProcess.run()
                certProcess.waitUntilExit()

                if certProcess.terminationStatus != 0 {
                    print("Failed to create certificate")
                    return
                }

                print("Certificate written to \(self.certificateURL.path)")

                // Convert PEM to DER
                let derCertURL = self.certificateURL.deletingPathExtension().appendingPathExtension("der")
                let convertProcess = Process()
                convertProcess.executableURL = URL(fileURLWithPath: self.opensslPath)
                convertProcess.arguments = ["x509", "-outform", "der", "-in", self.certificateURL.path, "-out", derCertURL.path]
                try convertProcess.run()
                convertProcess.waitUntilExit()

                if convertProcess.terminationStatus != 0 {
                    print("Failed to convert certificate to DER format")
                    return
                }

                DispatchQueue.main.async {
                    self.certificateExists = true
                    self.certificateCreationDate = Date()
                    print("Certificate generation and conversion completed.")
                    self.importCertificateToKeychain(derCertURL)
                    completion?()
                }
            } catch {
                print("Error generating certificate: \(error)")
            }
        }
    }

    private func importCertificateToKeychain(_ derCertURL: URL) {
        do {
            let certData = try Data(contentsOf: derCertURL)
            print("Certificate data: \(certData as NSData)") // Debugging: Print certificate data
            guard let certificate = SecCertificateCreateWithData(nil, certData as CFData) else {
                print("Failed to create SecCertificate object")
                return
            }

            let addQuery: [String: Any] = [
                kSecClass as String: kSecClassCertificate,
                kSecValueRef as String: certificate,
                kSecAttrLabel as String: "JoeProxy Certificate"
            ]

            let addStatus = SecItemAdd(addQuery as CFDictionary, nil)
            if addStatus == errSecSuccess {
                print("Certificate added to keychain successfully")
            } else if addStatus == errSecDuplicateItem {
                print("Certificate already exists in keychain, skipping import")
            } else {
                if let errorMessage = SecCopyErrorMessageString(addStatus, nil) {
                    print("Failed to add certificate to keychain: \(errorMessage)")
                } else {
                    print("Failed to add certificate to keychain with status: \(addStatus)")
                }
            }
        } catch {
            print("Error reading certificate data: \(error)")
        }
    }

    private func removeExistingCertificate() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: "JoeProxy Certificate"
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess {
            print("Existing certificate removed")
        } else if status == errSecItemNotFound {
            print("No existing certificate to remove")
        } else {
            if let errorMessage = SecCopyErrorMessageString(status, nil) {
                print("Failed to remove existing certificate: \(errorMessage)")
            } else {
                print("Failed to remove existing certificate with status: \(status)")
            }
        }
    }
}
