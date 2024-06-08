//
//  SimpleHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//
import Foundation
import NIO
import NIOHTTP1
import NIOSSL

final class SimpleHandler: ChannelInboundHandler {
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
            let filterDecision = filteringService.shouldAllowRequest(url: requestString) ? "allowed" : "blocked"
            loggingService.log("Request \(filterDecision): \(requestString)", level: .info)
            print("Request decision: \(filterDecision)")
            if filterDecision == "blocked" {
                let responseHead = HTTPResponseHead(version: request.version, status: .forbidden)
                context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
                let responseBody = HTTPServerResponsePart.body(.byteBuffer(context.channel.allocator.buffer(string: "Request blocked: \(request.uri)")))
                context.write(self.wrapOutboundOut(responseBody), promise: nil)
                context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                print("Blocked response sent")
            } else {
                let responseHead = HTTPResponseHead(version: request.version, status: .ok)
                context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
                let responseBody = HTTPServerResponsePart.body(.byteBuffer(context.channel.allocator.buffer(string: "Request allowed: \(request.uri)")))
                context.write(self.wrapOutboundOut(responseBody), promise: nil)
                context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
                print("Allowed response sent")
            }
        case .body, .end:
            break
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("SimpleHandler encountered error: \(error)")
        context.close(promise: nil)
    }
}
