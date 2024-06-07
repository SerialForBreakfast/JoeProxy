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
            loggingService.logRequest(requestString, headers: request.headers.reduce(into: [:]) { $0[$1.name] = $1.value }, timestamp: Date())

            let filterDecision = filteringService.shouldAllowRequest(url: requestString) ? "allowed" : "blocked"
            loggingService.log("Request \(filterDecision): \(requestString)", level: .info)

            if filterDecision == "blocked" {
                let responseHead = HTTPResponseHead(version: request.version, status: .forbidden)
                context.write(wrapOutboundOut(.head(responseHead)), promise: nil)
                context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
                return
            }

            // Forward request to the target server
            forwardRequestToTargetServer(request: request, context: context)
        case .body(let body):
            // Forward body if necessary
            context.write(wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
        case .end:
            // End of the request
            context.writeAndFlush(wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("Error: \(error)", level: .error)
        context.close(promise: nil)
    }

    private func forwardRequestToTargetServer(request: HTTPRequestHead, context: ChannelHandlerContext) {
        // Extract target host and port from request.uri
        guard let targetURL = URL(string: request.uri) else {
            loggingService.log("Invalid URL: \(request.uri)", level: .error)
            context.close(promise: nil)
            return
        }

        let targetHost = targetURL.host ?? ""
        let targetPort = targetURL.port ?? 443

        let bootstrap = ClientBootstrap(group: context.eventLoop)
            .channelInitializer { channel in
                let sslContext = try! NIOSSLContext(configuration: .makeClientConfiguration())
                let sslHandler = try! NIOSSLClientHandler(context: sslContext, serverHostname: targetHost)
                return channel.pipeline.addHandler(sslHandler).flatMap {
                    channel.pipeline.addHTTPClientHandlers().flatMap {
                        channel.pipeline.addHandler(SimpleProxyHandler(context: context, loggingService: self.loggingService))
                    }
                }
            }

        bootstrap.connect(host: targetHost, port: targetPort).whenComplete { result in
            switch result {
            case .success(let targetChannel):
                let head = HTTPRequestHead(version: request.version, method: request.method, uri: request.uri, headers: request.headers)
                targetChannel.write(NIOAny(HTTPClientRequestPart.head(head)), promise: nil)
                targetChannel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil)), promise: nil)
            case .failure(let error):
                self.loggingService.log("Failed to connect to target: \(error)", level: .error)
                context.close(promise: nil)
            }
        }
    }
}

class SimpleProxyHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPServerResponsePart

    private let context: ChannelHandlerContext
    private let loggingService: LoggingService

    init(context: ChannelHandlerContext, loggingService: LoggingService) {
        self.context = context
        self.loggingService = loggingService
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .head(let response):
            let responseHead = HTTPResponseHead(version: response.version, status: response.status, headers: response.headers)
            self.context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        case .body(let body):
            self.context.write(self.wrapOutboundOut(.body(.byteBuffer(body))), promise: nil)
        case .end:
            self.context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("Error: \(error)", level: .error)
        context.close(promise: nil)
    }
}
