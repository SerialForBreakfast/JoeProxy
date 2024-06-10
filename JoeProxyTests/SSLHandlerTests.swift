//
//  SSLHandlerTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/8/24.
//
import XCTest
import NIO
import NIOHTTP1
import NIOSSL
@testable import JoeProxy

final class SSLHandlerTests: XCTestCase {
    var group: MultiThreadedEventLoopGroup!
    var channel: EmbeddedChannel!
    var filteringService: FilteringService!
    var loggingService: MockLoggingService!
    var handler: SSLHandler!

    override func setUpWithError() throws {
        super.setUp()

        configurationService = BasicConfigurationService()
        loggingService = DefaultLoggingService(configurationService: configurationService)
        filteringService = DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow))
        certificateService = CertificateService(debug: true)
        networkingService = DefaultNetworkingService(
            configurationService: configurationService,
            filteringService: filteringService,
            loggingService: loggingService,
            certificateService: certificateService
        )

        try? FileManager.default.removeItem(at: certificateService.certificateURL)
        try? FileManager.default.removeItem(at: certificateService.pemURL)

        let expectation = XCTestExpectation(description: "Certificate generation")
        certificateService.generateCertificate {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10)

        let serverStartExpectation = XCTestExpectation(description: "Server start")
        networkingService.startServer { result in
            switch result {
            case .success():
                print("Server started successfully.")
                serverStartExpectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to start server: \(error)")
                serverStartExpectation.fulfill()
            }
        }
        wait(for: [serverStartExpectation], timeout: 10)
    }
    override func tearDown() {
        XCTAssertNoThrow(try channel.finish())
        XCTAssertNoThrow(try group.syncShutdownGracefully())
    }

    func testRequestAllowed() {
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/allowed")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        XCTAssertEqual(loggingService.loggedMessages.last, "[INFO] Request allowed: GET /allowed")
    }

    func testRequestBlocked() {
        let requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/blocked")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        XCTAssertEqual(loggingService.loggedMessages.last, "[INFO] Request blocked: GET /blocked")
    }

    // Additional tests for body handling, errors, etc.
}
