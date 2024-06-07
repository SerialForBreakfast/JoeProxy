//
//  CertificateServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/7/24.
//
import XCTest
@testable import JoeProxy

class CertificateServiceTests: XCTestCase {
    
    var certificateService: MockCertificateService!
    var opensslInstaller: MockOpenSSLInstaller!
    
    override func setUpWithError() throws {
        opensslInstaller = MockOpenSSLInstaller()
        certificateService = MockCertificateService(opensslInstaller: opensslInstaller)
    }
    
    override func tearDownWithError() throws {
        certificateService = nil
        opensslInstaller = nil
    }
    
    func testGenerateCertificate() throws {
        let expectation = self.expectation(description: "Generate Certificate")
        
        certificateService.generateCertificate()
        
        DispatchQueue.global().asyncAfter(deadline: .now() + 1) {
            XCTAssertTrue(self.certificateService.certificateExists, "Certificate should exist after generation")
            XCTAssertNotNil(self.certificateService.certificateCreationDate, "Certificate creation date should not be nil")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
    
    func testInstallOpenSSL() throws {
        opensslInstaller.installOpenSSL()
        XCTAssertTrue(opensslInstaller.installCalled, "Install OpenSSL should have been called")
    }
    
    func testFindOpenSSL() throws {
        let path = opensslInstaller.findOpenSSL()
        XCTAssertTrue(opensslInstaller.findCalled, "Find OpenSSL should have been called")
        XCTAssertEqual(path, "/mock/path/to/openssl", "Mock path should be returned")
    }
}
