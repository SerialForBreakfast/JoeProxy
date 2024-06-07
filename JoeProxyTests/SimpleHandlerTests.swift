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

final class SimpleHandlerTests: XCTestCase {

    func testAllowRequest() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService = MockLoggingService()
        let handler = SimpleHandler(filteringService: filteringService, loggingService: loggingService)
        let channel = EmbeddedChannel(handler: handler)

        let requestHead = HTTPRequestHead(version: .init(major: 1, minor: 1), method: .GET, uri: "https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        var buffer = channel.allocator.buffer(capacity: 0)
        buffer.writeString("")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.body(buffer)))

        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.end(nil)))

        var receivedResponse = false
        while let responsePart = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            switch responsePart {
            case .head(let responseHead):
                XCTAssertEqual(responseHead.status, .ok)
                receivedResponse = true
                print("Response head received with status: \(responseHead.status)")
            case .body(let responseBody):
                if case .byteBuffer(let byteBuffer) = responseBody {
                    let responseData = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes)
                    XCTAssertEqual(responseData, "Request allowed: https://example.com/test")
                    print("Response body received with data: \(responseData)")
                } else {
                    XCTFail("Expected ByteBuffer in response body")
                }
            case .end:
                print("Response end received")
                break
            }
        }

        XCTAssertTrue(receivedResponse, "Client did not receive response from server")
        XCTAssertNoThrow(try channel.finish())
    }

    func testBlockRequest() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService = MockLoggingService()
        let handler = SimpleHandler(filteringService: filteringService, loggingService: loggingService)
        let channel = EmbeddedChannel(handler: handler)

        let requestHead = HTTPRequestHead(version: .init(major: 1, minor: 1), method: .GET, uri: "https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        var buffer = channel.allocator.buffer(capacity: 0)
        buffer.writeString("")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.body(buffer)))

        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.end(nil)))

        var receivedResponse = false
        while let responsePart = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            switch responsePart {
            case .head(let responseHead):
                XCTAssertEqual(responseHead.status, .forbidden)
                receivedResponse = true
                print("Response head received with status: \(responseHead.status)")
            case .body(let responseBody):
                if case .byteBuffer(let byteBuffer) = responseBody {
                    let responseData = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes)
                    XCTAssertEqual(responseData, "Request blocked: https://example.com/test")
                    print("Response body received with data: \(responseData)")
                } else {
                    XCTFail("Expected ByteBuffer in response body")
                }
            case .end:
                print("Response end received")
                break
            }
        }

        XCTAssertTrue(receivedResponse, "Client did not receive response from server")
        XCTAssertNoThrow(try channel.finish())
    }
}
