//
//  SimpleHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation
import NIO

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
