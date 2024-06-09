//
//  CertificateServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/7/24.
//
import XCTest
@testable import JoeProxy

class CertificateServiceTests: XCTestCase {
    
    var certificateService: CertificateService!
    
    override func setUpWithError() throws {
        certificateService = CertificateService(debug: true)
        // Clean up any existing certificates before each test
        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)
        certificateService.checkCertificateExists()
    }
    
    override func tearDownWithError() throws {
        // Clean up any certificates created during tests
        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)
        certificateService = nil
    }
    
    func testGenerateCertificate() {
        certificateService.generateCertificate()
        
        // Wait for the certificate generation process to complete
        let expectation = XCTestExpectation(description: "Wait for certificate generation")
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)
        
        // Check if the certificate and private key files exist
        XCTAssertTrue(FileManager.default.fileExists(atPath: certificateService.certificateURL.path))
        XCTAssertTrue(FileManager.default.fileExists(atPath: certificateService.pemURL.path))
        
        // Check if the certificate exists in the service
        XCTAssertTrue(certificateService.certificateExists)
        XCTAssertNotNil(certificateService.certificateCreationDate)
    }
}
