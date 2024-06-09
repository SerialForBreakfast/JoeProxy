import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

final class DefaultNetworkingServiceTests: XCTestCase {

    var networkingService: MockDefaultNetworkingService!
    var configurationService: MockDefaultNetworkingConfigurationService!
    var certificateService: MockCertificateService!
    
    override func setUpWithError() throws {
        configurationService = MockDefaultNetworkingConfigurationService()
        configurationService.proxyPort = 8081 // Use a non-restricted port
        certificateService = MockCertificateService()
    }
    
    override func tearDownWithError() throws {
        try? networkingService.stopServer() // Use try? to safely attempt stopping the server
        networkingService = nil
        configurationService = nil
        certificateService = nil
    }

    func testNetworkingServiceWithAllowListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService, certificateService: certificateService)

        XCTAssertNoThrow(try networkingService.startServer())

        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService, loggingService: loggingService))

        let requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        var buffer = channel.allocator.buffer(capacity: 0)
        buffer.writeString("")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.body(buffer)))

        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.end(nil)))

        // Read the responses
        var responseParts: [HTTPServerResponsePart] = []
        while let part = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            responseParts.append(part)
        }

        guard let responseHead = responseParts.first(where: {
            if case .head = $0 {
                return true
            }
            return false
        }) else {
            XCTFail("No response head received")
            return
        }

        switch responseHead {
        case .head(let head):
            XCTAssertEqual(head.status, .ok)
        default:
            XCTFail("Unexpected response part received")
        }
    }

    func testNetworkingServiceWithBlockListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService, certificateService: certificateService)

        XCTAssertNoThrow(try networkingService.startServer())

        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService, loggingService: loggingService))

        let requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))

        var buffer = channel.allocator.buffer(capacity: 0)
        buffer.writeString("")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.body(buffer)))

        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.end(nil)))

        // Read the responses
        var responseParts: [HTTPServerResponsePart] = []
        while let part = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            responseParts.append(part)
        }

        guard let responseHead = responseParts.first(where: {
            if case .head = $0 {
                return true
            }
            return false
        }) else {
            XCTFail("No response head received")
            return
        }

        switch responseHead {
        case .head(let head):
            XCTAssertEqual(head.status, .forbidden)
        default:
            XCTFail("Unexpected response part received")
        }

        var receivedResponse = false
        for part in responseParts {
            if case .body(let buffer) = part {
                if case .byteBuffer(let byteBuffer) = buffer {
                    let responseData = byteBuffer.getString(at: byteBuffer.readerIndex, length: byteBuffer.readableBytes)
                    XCTAssertEqual(responseData, "Request blocked: https://example.com/test")
                    receivedResponse = true
                }
            }
        }

        XCTAssertTrue(receivedResponse, "Client did not receive response from server")
    }
}
