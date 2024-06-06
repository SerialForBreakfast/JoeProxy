//
//  NetworkingService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation
import NIO
import NIOSSL

protocol NetworkingService {
    func startServer() throws
    func stopServer() throws
}

class DefaultNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private var group: MultiThreadedEventLoopGroup?
    private var channel: Channel?
    
    init(configurationService: ConfigurationService) {
        self.configurationService = configurationService
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
                    channel.pipeline.addHandler(SimpleHandler())
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

final class SimpleHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let byteBuffer = self.unwrapInboundIn(data)
        let string = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) ?? ""
        print("Received: \(string)")
        
        var buffer = context.channel.allocator.buffer(capacity: byteBuffer.readableBytes)
        buffer.writeString("Echo: \(string)")
        context.writeAndFlush(self.wrapOutboundOut(buffer), promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}
