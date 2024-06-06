import XCTest
import NIO
@testable import JoeProxy

class DefaultNetworkingServiceTests: XCTestCase {
    
    var networkingService: MockDefaultNetworkingService!
    var configurationService: MockDefaultNetworkingConfigurationService!
    
    override func setUpWithError() throws {
        configurationService = MockDefaultNetworkingConfigurationService()
        configurationService.proxyPort = 8080
        networkingService = MockDefaultNetworkingService(configurationService: configurationService)
    }

    override func tearDownWithError() throws {
        try? networkingService.stopServer() // Use try? to safely attempt stopping the server
        networkingService = nil
        configurationService = nil
    }

    func testStartAndStopServer() throws {
        XCTAssertNoThrow(try networkingService.startServer())
        XCTAssertNoThrow(try networkingService.stopServer())
    }

    func testEchoHandler() throws {
        let channel = EmbeddedChannel(handler: EchoHandler())

        // Simulate writing data to the channel
        var buffer = channel.allocator.buffer(capacity: 256)
        buffer.writeString("Hello, world!")
        print("Client sending: \(buffer.getString(at: 0, length: buffer.readableBytes) ?? "")")
        XCTAssertNoThrow(try channel.writeInbound(buffer))

        // Read the echoed response
        if let responseBuffer = try channel.readOutbound(as: ByteBuffer.self) {
            let responseData = responseBuffer.getString(at: 0, length: responseBuffer.readableBytes)
            print("Client received: \(responseData ?? "")")
            XCTAssertEqual(responseData, "Echo: Hello, world!")
        } else {
            XCTFail("Client did not receive echoed data from server")
        }
        
        XCTAssertNoThrow(try channel.finish())
    }
}

// Mock Networking Service to avoid actual network operations
class MockDefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private var isServerRunning = false
    
    init(configurationService: ConfigurationService) {
        self.configurationService = configurationService
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
    var proxyPort: Int = 8080
    var logLevel: LogLevel = .info
}

// Handler for echoing received messages back to the client
final class EchoHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let byteBuffer = self.unwrapInboundIn(data)
        let string = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) ?? ""
        print("EchoHandler received: \(string)")
        
        var buffer = context.channel.allocator.buffer(capacity: byteBuffer.readableBytes)
        buffer.writeString("Echo: \(string)")
        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}
