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
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService)
        
        XCTAssertNoThrow(try networkingService.startServer())
        XCTAssertNoThrow(try networkingService.stopServer())
    }

    func testNetworkingServiceWithAllowListFiltering() throws {
        let criteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: criteria)
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService, loggingService: loggingService))

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
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        networkingService = MockDefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService)
        
        let channel = EmbeddedChannel(handler: SimpleHandler(filteringService: filteringService, loggingService: loggingService))

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
}
