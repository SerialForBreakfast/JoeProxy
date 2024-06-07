import Foundation
import NIO
import NIOSSL

protocol NetworkingService {
    func startServer() throws
    func stopServer() throws
}

import NIOSSL

class DefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private let loggingService: LoggingService
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    
    init(configurationService: ConfigurationService, filteringService: FilteringService, loggingService: LoggingService, group: MultiThreadedEventLoopGroup? = nil) {
        self.configurationService = configurationService
        self.filteringService = filteringService
        self.loggingService = loggingService
        self.group = group
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
                    channel.pipeline.addHandler(SimpleHandler(filteringService: self.filteringService, loggingService: self.loggingService))
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
