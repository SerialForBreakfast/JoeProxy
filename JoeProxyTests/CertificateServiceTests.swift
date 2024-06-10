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
        super.setUp()
        certificateService = CertificateService()
        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)
    }

    override func tearDownWithError() throws {
        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)
        certificateService = nil
        super.tearDown()
    }

    func testGenerateCertificate() {
        let expectation = XCTestExpectation(description: "Wait for certificate generation")

        certificateService.generateCertificate(
            commonName: "Test Common Name",
            organization: "Test Organization",
            organizationalUnit: "Test OU",
            country: "US",
            state: "Test State",
            locality: "Test Locality", completion: nil
        )

        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.certificateService.certificateURL.path))
            XCTAssertTrue(FileManager.default.fileExists(atPath: self.certificateService.pemURL.path))
            XCTAssertTrue(self.certificateService.certificateExists)
            XCTAssertNotNil(self.certificateService.certificateCreationDate)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 10)
    }
}
