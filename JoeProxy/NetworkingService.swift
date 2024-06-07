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
    private let loggingService: LoggingService
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    
    init(configurationService: ConfigurationService, filteringService: FilteringService, loggingService: LoggingService) {
        self.configurationService = configurationService
        self.filteringService = filteringService
        self.loggingService = loggingService
    }
    
    func startServer() throws {
        let group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        self.group = group
        
        let sslContext = try NIOSSLContext(configuration: .makeServerConfiguration(
            certificateChain: try NIOSSLCertificate.fromPEMFile("cert.pem").map { .certificate($0) },
            privateKey: .file("key.pem")
        ))
        
        let bootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socket(SocketOptionLevel(SOL_SOCKET), SO_REUSEADDR), value: 1)
            .childChannelInitializer { channel in
                let sslHandler = try! NIOSSLServerHandler(context: sslContext)
                return channel.pipeline.addHandler(sslHandler).flatMap {
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
