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
            let headers = request.headers.reduce(into: [String: String]()) { $0[$1.name] = $1.value }
            loggingService.logRequest(requestString, headers: headers, timestamp: Date())
            let filterDecision = filteringService.shouldAllowRequest(url: request.uri) ? "allowed" : "blocked"
            loggingService.log("Request \(filterDecision): \(requestString)", level: .info)
            
            if filterDecision == "blocked" {
                let responseHead = HTTPResponseHead(version: request.version, status: .forbidden)
                let response = HTTPServerResponsePart.head(responseHead)
                context.write(self.wrapOutboundOut(response), promise: nil)
                
                var buffer = context.channel.allocator.buffer(capacity: 256)
                buffer.writeString("Request blocked: \(request.uri)")
                context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
                
                context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                return
            }
            
        case .body, .end:
            // Handle body and end parts if needed
            break
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("Error: \(error)", level: .error)
        context.close(promise: nil)
    }
}
