import Foundation
import NIO
import NIOSSL

protocol NetworkingService {
    func startServer() throws
    func stopServer() throws
}

class DefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    
    init(configurationService: ConfigurationService, filteringService: FilteringService) {
        self.configurationService = configurationService
        self.filteringService = filteringService
    }
    
    func startServer() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.group = group
        
        let sslContext = try NIOSSLContext(configuration: .makeClientConfiguration())
        let sslHandler = try NIOSSLClientHandler(context: sslContext, serverHostname: nil)
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.addHandler(sslHandler).flatMap {
                    channel.pipeline.addHandler(SimpleHandler(filteringService: self.filteringService))
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        self.channel = try bootstrap.bind(host: "localhost", port: configurationService.proxyPort).wait()
        print("Server started and listening on \(String(describing: channel?.localAddress))")
    }
    
    func stopServer() throws {
        try self.channel?.close().wait()
        try self.group?.syncShutdownGracefully()
        print("Server stopped.")
    }
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
