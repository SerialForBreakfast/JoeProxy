//
//  SimpleHandlerTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/6/24.
//

import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

class SimpleHandlerTests: XCTestCase {

    func testNetworkingServiceWithBlockListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let configurationService = MockDefaultNetworkingConfigurationService()
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        
        let handler = SimpleHandler(filteringService: filteringService, loggingService: loggingService)
        let channel = EmbeddedChannel(handler: handler)

        // Simulate an HTTP request
        let requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        var buffer = channel.allocator.buffer(capacity: 0)
        buffer.writeString("")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.body(buffer)))

        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.end(nil)))

        // Read the response
        var receivedResponse = false
        while let responsePart = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            switch responsePart {
            case .head(let responseHead):
                XCTAssertEqual(responseHead.status, .forbidden)
                receivedResponse = true
            case .body(let responseBody):
                if case .byteBuffer(let byteBuffer) = responseBody {
                    let responseData = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes)
                    XCTAssertEqual(responseData, "Request blocked: https://example.com/test")
                } else {
                    XCTFail("Expected ByteBuffer in response body")
                }
            case .end:
                break
            }
        }

        XCTAssertTrue(receivedResponse, "Client did not receive response from server")
        XCTAssertNoThrow(try channel.finish())
    }
}
