//
//  SSLHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/7/24.
//

import NIO
import NIOHTTP1
import NIOSSL
import Foundation

final class SSLHandler: ChannelInboundHandler {
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
        case .head(let requestHead):
            handleRequestHead(context: context, requestHead: requestHead)
        case .body(let requestBody):
            handleRequestBody(context: context, requestBody: requestBody)
        case .end:
            handleRequestEnd(context: context)
        }
    }

    private func handleRequestHead(context: ChannelHandlerContext, requestHead: HTTPRequestHead) {
        let requestString = "\(requestHead.method) \(requestHead.uri)"
        let headersDict = requestHead.headers.reduce(into: [String: String]()) { result, header in
            result[header.name] = header.value
        }
        loggingService.logRequest(requestString, headers: headersDict, timestamp: Date())

        if filteringService.shouldAllowRequest(url: requestHead.uri) {
            loggingService.log("Request allowed: \(requestString)", level: .info)
            sendResponse(context: context, status: .ok, body: "Request allowed: \(requestHead.uri)")
        } else {
            loggingService.log("Request blocked: \(requestString)", level: .info)
            sendResponse(context: context, status: .forbidden, body: "Request blocked: \(requestHead.uri)")
        }
    }

    private func handleRequestBody(context: ChannelHandlerContext, requestBody: ByteBuffer) {
        loggingService.log("Received body data: \(requestBody.readableBytes) bytes", level: .debug)
    }

    private func handleRequestEnd(context: ChannelHandlerContext) {
        loggingService.log("Request ended", level: .debug)
    }

    private func sendResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, body: String) {
        var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)

        let responseHead = HTTPResponseHead(version: .http1_1, status: status)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("SSLHandler encountered error: \(error)", level: .error)
        context.close(promise: nil)
    }
}
