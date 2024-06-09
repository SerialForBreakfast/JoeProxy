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

    override func setUp() {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        // Create a mock SSL context for testing
        let tlsConfig = TLSConfiguration.forServer(
            certificateChain: [],
            privateKey: .file("path/to/privateKey.pem"),
            trustRoots: .certificates([])
        )
        let sslContext = try! NIOSSLContext(configuration: tlsConfig)
        
        // Initialize the channel with the NIOSSLHandler and SSLHandler
        channel = EmbeddedChannel()
        try! channel.pipeline.addHandler(NIOSSLServerHandler(context: sslContext)).wait()
        
        filteringService = MockFilteringService(shouldAllow: true)
        loggingService = MockLoggingService()
        handler = SSLHandler(filteringService: filteringService, loggingService: loggingService)
        try! channel.pipeline.addHandler(handler).wait()
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
