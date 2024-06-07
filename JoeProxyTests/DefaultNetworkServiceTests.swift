import XCTest
import NIO
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
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService)
        
        XCTAssertNoThrow(try networkingService.startServer())
        XCTAssertNoThrow(try networkingService.stopServer())
    }

    func testNetworkingServiceWithAllowListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService))

        // Simulate a request
        var buffer = channel.allocator.buffer(capacity: 256)
        buffer.writeString("https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(buffer))

        // Read the response
        if let responseBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            let responseData = responseBuffer.getString(at: 0, length: responseBuffer.readableBytes)
            XCTAssertEqual(responseData, "Request allowed: https://example.com/test")
        } else {
            XCTFail("Client did not receive response from server")
        }
        
        XCTAssertNoThrow(try channel.finish())
    }

    func testNetworkingServiceWithBlockListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService))

        // Simulate a request
        var buffer = channel.allocator.buffer(capacity: 256)
        buffer.writeString("https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(buffer))

        // Read the response
        if let responseBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            let responseData = responseBuffer.getString(at: 0, length: responseBuffer.readableBytes)
            XCTAssertEqual(responseData, "Request blocked: https://example.com/test")
        } else {
            XCTFail("Client did not receive response from server")
        }
        
        XCTAssertNoThrow(try channel.finish())
    }

    func testNetworkingServiceWithEmptyAllowList() throws {
        let criteria = FilteringCriteria(urls: [], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService))

        // Simulate a request
        var buffer = channel.allocator.buffer(capacity: 256)
        buffer.writeString("https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(buffer))

        // Read the response
        if let responseBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            let responseData = responseBuffer.getString(at: 0, length: responseBuffer.readableBytes)
            XCTAssertEqual(responseData, "Request blocked: https://example.com/test")
        } else {
            XCTFail("Client did not receive response from server")
        }
        
        XCTAssertNoThrow(try channel.finish())
    }

    func testNetworkingServiceWithEmptyBlockList() throws {
        let criteria = FilteringCriteria(urls: [], filterType: .block)
        let filteringService = DefaultFilteringService(criteria: criteria)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService))

        // Simulate a request
        var buffer = channel.allocator.buffer(capacity: 256)
        buffer.writeString("https://example.com/test")
        XCTAssertNoThrow(try channel.writeInbound(buffer))

        // Read the response
        if let responseBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            let responseData = responseBuffer.getString(at: 0, length: responseBuffer.readableBytes)
            XCTAssertEqual(responseData, "Request allowed: https://example.com/test")
        } else {
            XCTFail("Client did not receive response from server")
        }
        
        XCTAssertNoThrow(try channel.finish())
    }
}

// Mock Networking Service to avoid actual network operations
class MockDefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private var isServerRunning = false
    
    init(configurationService: ConfigurationService, filteringService: FilteringService) {
        self.configurationService = configurationService
        self.filteringService = filteringService
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
}

// Handler for processing incoming requests and applying filtering criteria
final class SimpleHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let filteringService: FilteringService
    
    init(filteringService: FilteringService) {
        self.filteringService = filteringService
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let byteBuffer = self.unwrapInboundIn(data)
        let requestString = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) ?? ""
        
        print("Received request: \(requestString)")
        
        // Apply filtering
        if filteringService.shouldAllowRequest(url: requestString) {
            var responseBuffer = context.channel.allocator.buffer(capacity: byteBuffer.readableBytes)
            responseBuffer.writeString("Request allowed: \(requestString)")
            context.writeAndFlush(self.wrapOutboundOut(responseBuffer), promise: nil)
        } else {
            var responseBuffer = context.channel.allocator.buffer(capacity: byteBuffer.readableBytes)
            responseBuffer.writeString("Request blocked: \(requestString)")
            context.writeAndFlush(self.wrapOutboundOut(responseBuffer), promise: nil)
        }
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}
