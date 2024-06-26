import NIO
import NIOSSL
import NIOHTTP1
import Foundation

final class SSLHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let filteringService: FilteringService
    private let loggingService: LoggingService
    private var requestHead: HTTPRequestHead?
    private var requestBody: ByteBuffer?

    init(filteringService: FilteringService, loggingService: LoggingService) {
        self.filteringService = filteringService
        self.loggingService = loggingService
    }

    func channelActive(context: ChannelHandlerContext) {
        let remoteAddress: String = context.remoteAddress?.description ?? "unknown address"
        loggingService.log("SSL connection attempted from \(remoteAddress)", level: .info)
        print("SSL connection attempted from \(remoteAddress)")
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part: HTTPServerRequestPart = unwrapInboundIn(data)
        switch part {
        case .head(let requestHead):
            print("Received request head: \(requestHead)")
            self.requestHead = requestHead
        case .body(var requestBody):
            print("Received request body part with \(requestBody.readableBytes) bytes")
            if var existingBody = self.requestBody {
                existingBody.writeBuffer(&requestBody)
                self.requestBody = existingBody
            } else {
                self.requestBody = requestBody
            }
        case .end:
            print("Request end received.")
            handleRequestEnd(context: context)
        }
    }

    private func handleRequestEnd(context: ChannelHandlerContext) {
        guard let requestHead: HTTPRequestHead = requestHead else {
            context.close(promise: nil)
            return
        }

        let requestString: String = "\(requestHead.method) \(requestHead.uri)"
        let headersDict: [String: String] = requestHead.headers.reduce(into: [String: String]()) { result, header in
            result[header.name] = header.value
        }
        loggingService.logRequest(requestString, headers: headersDict, timestamp: Date())

        if filteringService.shouldAllowRequest(url: requestHead.uri) {
            loggingService.log("Request allowed: \(requestString)", level: .info)
            proxyRequest(context: context, requestHead: requestHead, requestBody: requestBody)
        } else {
            loggingService.log("Request blocked: \(requestString)", level: .info)
            sendResponse(context: context, status: .forbidden, body: "Request blocked: \(requestHead.uri)")
        }
    }

    private func proxyRequest(context: ChannelHandlerContext, requestHead: HTTPRequestHead, requestBody: ByteBuffer?) {
        guard let host: String = requestHead.headers["host"].first else {
            sendResponse(context: context, status: .badRequest, body: "Bad request: missing Host header")
            return
        }

        let bootstrap: ClientBootstrap = ClientBootstrap(group: context.eventLoop)
            .channelInitializer { channel in
                channel.pipeline.addHandler(HTTPClientHandler()).flatMap {
                    channel.pipeline.addHandler(HTTPClientResponseHandler(serverContext: context))
                }
            }
        let connect: EventLoopFuture<Channel> = bootstrap.connect(host: host, port: 80)
        connect.whenSuccess { channel in
            var headers: HTTPHeaders = requestHead.headers
            headers.remove(name: "Host")
            headers.add(name: "Host", value: host)
            let clientRequestHead: HTTPClientRequestPart = .head(HTTPRequestHead(version: requestHead.version, method: requestHead.method, uri: requestHead.uri, headers: headers))
            channel.write(NIOAny(clientRequestHead), promise: nil)
            if let body: ByteBuffer = requestBody {
                let clientRequestBody: HTTPClientRequestPart = .body(.byteBuffer(body))
                channel.write(NIOAny(clientRequestBody), promise: nil)
            }
            channel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil)), promise: nil)
        }
        connect.whenFailure { error in
            self.loggingService.log("Failed to connect to \(host): \(error)", level: .error)
            self.sendResponse(context: context, status: .internalServerError, body: "Failed to connect to upstream server")
        }
    }

    private func sendResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, body: String) {
        var buffer: ByteBuffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)

        let responseHead: HTTPResponseHead = HTTPResponseHead(version: .http1_1, status: status)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil))).whenComplete { _ in
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("SSLHandler encountered error: \(error)", level: .error)
        print("SSLHandler errorCaught - error: \(error), type: \(type(of: error))")
        context.close(promise: nil)
    }
}
