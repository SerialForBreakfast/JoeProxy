//
//  SimpleHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//
import Foundation
import NIO
import NIOHTTP1

class SimpleHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let filteringService: FilteringService
    private let loggingService: LoggingService

    init(filteringService: FilteringService, loggingService: LoggingService) {
        self.filteringService = filteringService
        self.loggingService = loggingService
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .head(let request):
            let requestString = "\(request.method) \(request.uri)"
            loggingService.log("[REQUEST] \(requestString)", level: .info)
            let filterDecision = filteringService.shouldAllowRequest(url: request.uri) ? "allowed" : "blocked"
            loggingService.log("Request \(filterDecision): \(requestString)", level: .info)
            
            if filterDecision == "blocked" {
                var buffer = context.channel.allocator.buffer(capacity: 256)
                buffer.writeString("Request blocked: \(request.uri)")
                let responseHead = HTTPResponseHead(version: request.version, status: .forbidden)
                context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
                context.write(wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
                loggingService.log("[RESPONSE] \(requestString) Status: 403", level: .info)
            } else {
                // Additional processing if the request is allowed
            }
            
        case .body, .end:
            break
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("Error: \(error)", level: .error)
        context.close(promise: nil)
    }
}
