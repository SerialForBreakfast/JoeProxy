import NIO
import NIOHTTP1
import NIOSSL
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

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
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
            print("Received request end")
            handleRequestEnd(context: context)
        }
    }

    private func handleRequestEnd(context: ChannelHandlerContext) {
        guard let requestHead = requestHead else {
            print("Request head is nil, closing context")
            context.close(promise: nil)
            return
        }

        let requestString = "\(requestHead.method) \(requestHead.uri)"
        let headersDict = requestHead.headers.reduce(into: [String: String]()) { result, header in
            result[header.name] = header.value
        }
        loggingService.logRequest(requestString, headers: headersDict, timestamp: Date())

        if filteringService.shouldAllowRequest(url: requestHead.uri) {
            loggingService.log("Request allowed: \(requestString)", level: .info)
            print("Request allowed: \(requestString)")
            proxyRequest(context: context, requestHead: requestHead, requestBody: requestBody)
        } else {
            loggingService.log("Request blocked: \(requestString)", level: .info)
            print("Request blocked: \(requestString)")
            sendResponse(context: context, status: .forbidden, body: "Request blocked: \(requestHead.uri)")
        }
    }

    private func proxyRequest(context: ChannelHandlerContext, requestHead: HTTPRequestHead, requestBody: ByteBuffer?) {
        guard let host = requestHead.headers["host"].first else {
            let errorMsg = "Bad request: missing Host header"
            print(errorMsg)
            sendResponse(context: context, status: .badRequest, body: errorMsg)
            return
        }

        let bootstrap = ClientBootstrap(group: context.eventLoop)
            .channelInitializer { channel in
                channel.pipeline.addHandler(HTTPClientHandler()).flatMap {
                    channel.pipeline.addHandler(HTTPClientResponseHandler(serverContext: context))
                }
            }
        let connect = bootstrap.connect(host: host, port: 80)
        connect.whenSuccess { channel in
            print("Connected to upstream server \(host)")
            var headers = requestHead.headers
            headers.remove(name: "Host")
            headers.add(name: "Host", value: host)
            let clientRequestHead = HTTPClientRequestPart.head(HTTPRequestHead(version: requestHead.version, method: requestHead.method, uri: requestHead.uri, headers: headers))
            channel.write(NIOAny(clientRequestHead), promise: nil)
            if let body = requestBody {
                let clientRequestBody = HTTPClientRequestPart.body(.byteBuffer(body))
                channel.write(NIOAny(clientRequestBody), promise: nil)
            }
            channel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil)), promise: nil)
        }
        connect.whenFailure { error in
            let errorMsg = "Failed to connect to \(host): \(error)"
            print(errorMsg)
            self.loggingService.log(errorMsg, level: .error)
            self.sendResponse(context: context, status: .internalServerError, body: "Failed to connect to upstream server")
        }
    }

    private func sendResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, body: String) {
        print("Sending response with status \(status): \(body)")
        var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)

        let responseHead = HTTPResponseHead(version: .http1_1, status: status)
        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil))).whenComplete { _ in
            print("Response sent, closing context")
            context.close(promise: nil)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        let errorMsg = "SSLHandler encountered error: \(error)"
        print(errorMsg)
        loggingService.log(errorMsg, level: .error)
        context.close(promise: nil)
    }
}
