//
//  ClientConnectionTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/8/24.
//

import XCTest
import NIO
import NIOHTTP1
import NIOSSL
@testable import JoeProxy

class ClientConnectionTests: XCTestCase {
    var group: MultiThreadedEventLoopGroup!
    var serverChannel: Channel!
    var clientChannel: Channel!
    
    override func setUpWithError() throws {
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        
        // Setup server
        let serverBootstrap = ServerBootstrap(group: group)
            .serverChannelOption(ChannelOptions.backlog, value: 256)
            .serverChannelOption(ChannelOptions.socketOption(.so_reuseaddr), value: 1)
            .childChannelInitializer { channel in
                channel.pipeline.configureHTTPServerPipeline(withErrorHandling: true).flatMap {
                    channel.pipeline.addHandler(HTTPServerHandler())
                }
            }
            .childChannelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .childChannelOption(ChannelOptions.maxMessagesPerRead, value: 16)
            .childChannelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        serverChannel = try serverBootstrap.bind(host: "localhost", port: 8443).wait()
    }
    
    override func tearDownWithError() throws {
        try serverChannel.close().wait()
        try group.syncShutdownGracefully()
    }
    
    func testClientConnection() throws {
        let clientBootstrap = ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().flatMap {
                    channel.pipeline.addHandler(HTTPClientHandler())
                }
            }
            .channelOption(ChannelOptions.socket(IPPROTO_TCP, TCP_NODELAY), value: 1)
            .channelOption(ChannelOptions.recvAllocator, value: AdaptiveRecvByteBufferAllocator())
        
        clientChannel = try clientBootstrap.connect(host: "localhost", port: 8443).wait()
        
        // Send request from client
        var requestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/")
        clientChannel.write(NIOAny(HTTPClientRequestPart.head(requestHead)), promise: nil)
        clientChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil)), promise: nil)
        
        // Wait for response
        let response = try clientChannel.pipeline.context(handlerType: HTTPClientHandler.self).flatMap { context in
            return (context.handler as! HTTPClientHandler).waitForResponse()
        }.wait()
        
        XCTAssertNotNil(response)
    }
}
