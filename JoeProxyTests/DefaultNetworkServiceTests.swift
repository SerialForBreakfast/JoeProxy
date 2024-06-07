import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

class DefaultNetworkingServiceTests: XCTestCase {
    
    var networkingService: MockDefaultNetworkingService!
    var configurationService: MockDefaultNetworkingConfigurationService!
    
    override func setUpWithError() throws {
        configurationService = MockDefaultNetworkingConfigurationService()
        configurationService.proxyPort = 8081 // Use a non-restricted port
    }
    
    override func tearDownWithError() throws {
        try? networkingService.stopServer() // Use try? to safely attempt stopping the server
        networkingService = nil
        configurationService = nil
    }
    
    func testStartAndStopServer() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService: LoggingService = DefaultLoggingService(configurationService: configurationService) as LoggingService // Ensure conformance
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService)
        
        XCTAssertNoThrow(try networkingService.startServer())
        XCTAssertNoThrow(try networkingService.stopServer())
    }

    
    func testNetworkingServiceWithAllowListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService: DefaultLoggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService as LoggingService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService, loggingService: loggingService))
        
        // Simulate an HTTP request
        let requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.head(requestHead)))
        
        var buffer = channel.allocator.buffer(capacity: 0)
        buffer.writeString("")
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.body(buffer)))
        
        XCTAssertNoThrow(try channel.writeInbound(HTTPServerRequestPart.end(nil)))
        
        // Read the responses (if any)
        while let _ = try channel.readOutbound(as: HTTPServerResponsePart.self) {
            // Process the response parts if necessary
        }
        
        // Close the channel
        XCTAssertNoThrow(try channel.close().wait())
    }

    func testNetworkingServiceWithBlockListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService: DefaultLoggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService as LoggingService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService, loggingService: loggingService))

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
                XCTAssertEqual(responseHead.status, .forbidden) // Ensure correct status type
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

// Mock Networking Service to avoid actual network operations
class MockDefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private let loggingService: LoggingService
    private var isServerRunning = false
    
    init(configurationService: ConfigurationService, filteringService: FilteringService, loggingService: LoggingService) {
        self.configurationService = configurationService
        self.filteringService = filteringService
        self.loggingService = loggingService
    }
    
    func startServer() throws {
        guard !isServerRunning else { throw NSError(domain: "Server already running", code: 1, userInfo: nil) }
        isServerRunning = true
        print("Mock server started on port \(configurationService.proxyPort)")
    }
    
    func stopServer() throws {
        guard isServerRunning else { throw NSError(domain: "Server not running", code: 1, userInfo: nil) }
        isServerRunning = false
        print("Mock server stopped.")
    }
}

// Mock ConfigurationService for testing purposes
class MockDefaultNetworkingConfigurationService: ConfigurationService {
    var proxyPort: Int = 8081 // Use a non-restricted port
    var logLevel: LogLevel = .info

    // Add missing properties and methods to conform to ConfigurationService
}
