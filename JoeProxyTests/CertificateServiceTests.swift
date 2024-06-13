import XCTest
@testable import JoeProxy

class CertificateServiceTests: XCTestCase {
    var certificateService: CertificateService!
    
    override func setUpWithError() throws {
        try super.setUpWithError()
        certificateService = CertificateService(debug: true)
        print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) \(#function)")
        print("removing certificateService.certificateURL \(certificateService.certificateURL)")
        print("removing certificateService.pemURL \(certificateService.pemURL)")
        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)
        
        let expectation = self.expectation(description: "Certificate generation")
        certificateService.generateCertificate {
            print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) Certificate generated")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
    }
    
    override func tearDownWithError() throws {
        print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) \(#function)")
        print("removing certificateService.certificateURL \(certificateService.certificateURL)")
        print("removing certificateService.pemURL \(certificateService.pemURL)")
        try FileManager.default.removeItem(at: certificateService.certificateURL)
        try FileManager.default.removeItem(at: certificateService.pemURL)
        certificateService = nil
        try super.tearDownWithError()
    }
    
    func testGenerateCertificate() {
        let expectation = self.expectation(description: "Wait for certificate generation")
        
        certificateService.generateCertificate(
            commonName: "Test Common Name",
            organization: "Test Organization",
            organizationalUnit: "Test OU",
            country: "US",
            state: "Test State",
            locality: "Test Locality", completion: nil
        )
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) Checking certificate and PEM existence")
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.certificateService.certificateURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.certificateService.pemURL.path))
            XCTAssertTrue(self.certificateService.certificateExists)
            XCTAssertNotNil(self.certificateService.certificateCreationDate)
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testGenerateKeyPair() throws {
        let expectation = self.expectation(description: "Certificate generation")
        certificateService.generateCertificate {
            print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) Certificate generated for testGenerateKeyPair")
            XCTAssertTrue(self.certificateService.certificateExists, "Certificate should exist")
            XCTAssertNotNil(self.certificateService.certificateCreationDate, "Certificate creation date should not be nil")
            
            do {
                let certificateData: Data = try Data(contentsOf: self.certificateService.certificateURL)
                let certificateString: String? = String(data: certificateData, encoding: .utf8)
                XCTAssertNotNil(certificateString, "Certificate string should not be nil")
                print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) Certificate string: \(certificateString ?? "")")
                
                self.validateCertificate(certificatePath: self.certificateService.certificateURL.path)
                
            } catch {
                XCTFail("Failed to read certificate: \(error)")
            }
            
            expectation.fulfill()
        }
        waitForExpectations(timeout: 10, handler: nil)
    }
    
    func testCheckCertificateExists() {
        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)
        
        let expectation = self.expectation(description: "Certificate generation")
        certificateService.generateCertificate {
            print("💡 \(URL(fileURLWithPath: #file).lastPathComponent):\(#line) Certificate generated for testCheckCertificateExists")
            self.certificateService.checkCertificateExists()
            XCTAssertTrue(self.certificateService.certificateExists, "Certificate should exist")
            XCTAssertNotNil(self.certificateService.certificateCreationDate, "Certificate creation date should be set")
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 10)
    }
    
    func testSetup() {
        certificateService.setup()
        XCTAssertNotEqual(certificateService.opensslPath, "", "OpenSSL path should not be empty")
        print("OpenSSL path: \(certificateService.opensslPath)")
    }
    
    func testValidateCertificate() {
        // Assuming the certificateService instance is available
        let certificatePath = certificateService.certificateURL
        let arguments = ["x509", "-in", certificatePath.path, "-noout", "-text"]
        
        let output = validateFile(at: certificatePath, withArguments: arguments)
        print("Validation Output: \(output)")
        
        XCTAssertTrue(output.contains("BEGIN CERTIFICATE"), "Output should contain certificate beginning")
        XCTAssertTrue(output.contains("END CERTIFICATE"), "Output should contain certificate ending")
    }
    private func validateFile(at path: URL, withArguments arguments: [String]) -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: certificateService.opensslPath)
        process.arguments = arguments

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = outputPipe

        let outputHandle = outputPipe.fileHandleForReading
        outputHandle.readabilityHandler = { pipe in
            let outputData = pipe.availableData
            if let outputString = String(data: outputData, encoding: .utf8) {
                print(outputString)
            }
        }

        do {
            try process.run()
            process.waitUntilExit()
            
            let outputData = outputHandle.readDataToEndOfFile()
            outputHandle.readabilityHandler = nil
            
            if let outputString = String(data: outputData, encoding: .utf8) {
                return outputString
            } else {
                return "Failed to decode output"
            }
        } catch {
            return "Failed to run process: \(error)"
        }
    }

    
    private func validateCertificate(certificatePath: String) {
        do {
            let output = try validateFile(at: URL(fileURLWithPath: certificatePath), withArguments: ["x509", "-noout", "-text"])
            print("Validating certificate at path \(certificatePath)")
            print("OpenSSL output: \(output)")
            
            guard output.contains("BEGIN CERTIFICATE") && output.contains("END CERTIFICATE") else {
                print("Output should contain certificate beginning and ending")
                return
            }
            
            // Additional parsing logic to check for expected fields
            let parsedCertificate = parseCertificate(output: output)
            print("Parsed certificate: \(parsedCertificate)")
            
            XCTAssertTrue(parsedCertificate.issuer.contains("CN=Test Common Name"), "Certificate issuer should contain 'CN=Test Common Name'")
            XCTAssertTrue(parsedCertificate.subject.contains("CN=Test Common Name"), "Certificate subject should contain 'CN=Test Common Name'")
            XCTAssertTrue(parsedCertificate.subject.contains("O=Test Organization"), "Certificate subject should contain 'O=Test Organization'")
            XCTAssertTrue(parsedCertificate.subject.contains("OU=Test OU"), "Certificate subject should contain 'OU=Test OU'")
            XCTAssertTrue(parsedCertificate.subject.contains("ST=Test State"), "Certificate subject should contain 'ST=Test State'")
            XCTAssertTrue(parsedCertificate.subject.contains("L=Test Locality"), "Certificate subject should contain 'L=Test Locality'")
            
        } catch {
            print("Error validating certificate: \(error)")
        }
    }
    
    private func parseCertificate(output: String) -> Certificate {
        let lines = output.components(separatedBy: "\n")
        
        var version: Int?
        var serialNumber: String?
        var signatureAlgorithm: String?
        var issuer: String?
        var validityPeriod: String?
        var subject: String?
        var publicKeyAlgorithm: String?
        var modulus: String = ""
        var exponent: String?
        
        var isModulus = false
        
        for line in lines {
            if line.contains("Version:") {
                version = Int(line.components(separatedBy: ": ")[1])
            } else if line.contains("Serial Number:") {
                serialNumber = line.components(separatedBy: ": ")[1]
            } else if line.contains("Signature Algorithm:") {
                signatureAlgorithm = line.components(separatedBy: ": ")[1]
            } else if line.contains("Issuer:") {
                issuer = line.components(separatedBy: ": ")[1]
            } else if line.contains("Not Before:") {
                validityPeriod = line
            } else if line.contains("Not After :") {
                validityPeriod = (validityPeriod ?? "") + " - " + line
            } else if line.contains("Subject:") {
                subject = line.components(separatedBy: ": ")[1]
            } else if line.contains("Public Key Algorithm:") {
                publicKeyAlgorithm = line.components(separatedBy: ": ")[1]
            } else if line.contains("Modulus:") {
                isModulus = true
            } else if line.contains("Exponent:") {
                exponent = line.components(separatedBy: ": ")[1]
                isModulus = false
            } else if isModulus {
                modulus += line.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return Certificate(
            version: version ?? 0,
            serialNumber: serialNumber ?? "",
            signatureAlgorithm: signatureAlgorithm ?? "",
            issuer: issuer ?? "",
            validityPeriod: validityPeriod ?? "",
            subject: subject ?? "",
            publicKeyAlgorithm: publicKeyAlgorithm ?? "",
            modulus: modulus,
            exponent: exponent ?? ""
        )
    }
}




struct Certificate {
    let version: Int
    let serialNumber: String
    let signatureAlgorithm: String
    let issuer: String
    let validityPeriod: String
    let subject: String
    let publicKeyAlgorithm: String
    let modulus: String
    let exponent: String
    
    static func parse(from output: String) -> Certificate? {
        guard let version = output.captureGroup(pattern: "Version: (\\d+)"),
              let serialNumber = output.captureGroup(pattern: "Serial Number:\\s+([\\w:]+)"),
              let signatureAlgorithm = output.captureGroup(pattern: "Signature Algorithm: (.+)"),
              let issuer = output.captureGroup(pattern: "Issuer: (.+)"),
              let validityPeriod = output.captureGroup(pattern: "Validity\\s+Not Before: (.+?)\\s+Not After : (.+?)\\s"),
              let subject = output.captureGroup(pattern: "Subject: (.+)"),
              let publicKeyAlgorithm = output.captureGroup(pattern: "Public Key Algorithm: (.+)"),
              let modulus = output.captureGroup(pattern: "Modulus:\\s+([\\s\\S]+?)\\s+Exponent"),
              let exponent = output.captureGroup(pattern: "Exponent: (\\d+) \\(0x\\d+\\)") else {
            return nil
        }
        
        return Certificate(
            version: Int(version) ?? 0,
            serialNumber: serialNumber,
            signatureAlgorithm: signatureAlgorithm,
            issuer: issuer,
            validityPeriod: validityPeriod,
            subject: subject,
            publicKeyAlgorithm: publicKeyAlgorithm,
            modulus: modulus.replacingOccurrences(of: "\\s+", with: "", options: .regularExpression),
            exponent: exponent
        )
    }
}

extension String {
    func captureGroup(pattern: String) -> String? {
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsString = self as NSString
            let results = regex.matches(in: self, range: NSRange(location: 0, length: nsString.length))
            return results.first.map { nsString.substring(with: $0.range(at: 1)) }
        } catch let error {
            print("Invalid regex: \(error.localizedDescription)")
            return nil
        }
    }
}
