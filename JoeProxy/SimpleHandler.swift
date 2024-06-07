//
//  SimpleHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//
import Foundation
import NIO

final class SimpleHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer
    
    private let filteringService: FilteringService
    private let loggingService: LoggingService
    
    init(filteringService: FilteringService, loggingService: LoggingService) {
        self.filteringService = filteringService
        self.loggingService = loggingService
    }
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let byteBuffer = self.unwrapInboundIn(data)
        let requestString = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) ?? ""
        
        loggingService.log("Received request: \(requestString)", level: .info)
        
        // Apply filtering
        let filterDecision = filteringService.shouldAllowRequest(url: requestString) ? "allowed" : "blocked"
        loggingService.log("Request \(filterDecision): \(requestString)", level: .info)
        
        var responseBuffer = context.channel.allocator.buffer(capacity: byteBuffer.readableBytes)
        responseBuffer.writeString("Request \(filterDecision): \(requestString)")
        loggingService.log("Response: \(responseBuffer.getString(at: 0, length: responseBuffer.readableBytes) ?? "")", level: .info)
        
        context.writeAndFlush(self.wrapOutboundOut(responseBuffer), promise: nil)
    }
    
    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("Error: \(error)", level: .error)
        context.close(promise: nil)
    }
}
