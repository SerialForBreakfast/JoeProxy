import NIO
import NIOHTTP1
import NIOSSL
import Foundation

final class SSLHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    private let filteringService: FilteringService
    private let loggingService: LoggingService

    private var targetChannel: Channel?

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
            setupTargetChannel(context: context, requestHead: requestHead)
        } else {
            loggingService.log("Request blocked: \(requestString)", level: .info)
            sendResponse(context: context, status: .forbidden, body: "Request blocked: \(requestHead.uri)")
        }
    }

    private func handleRequestBody(context: ChannelHandlerContext, requestBody: ByteBuffer) {
        loggingService.log("Received body data: \(requestBody.readableBytes) bytes", level: .debug)
        targetChannel?.write(NIOAny(HTTPClientRequestPart.body(.byteBuffer(requestBody))), promise: nil)
    }

    private func handleRequestEnd(context: ChannelHandlerContext) {
        loggingService.log("Request ended", level: .debug)
        targetChannel?.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil)), promise: nil)
    }

    private func setupTargetChannel(context: ChannelHandlerContext, requestHead: HTTPRequestHead) {
        let bootstrap = ClientBootstrap(group: context.eventLoop)
            .channelInitializer { channel in
                channel.pipeline.addHandler(HTTPClientHandler()).flatMap {
                    channel.pipeline.addHandler(HTTPClientResponseHandler(serverContext: context))
                }
            }

        let host = "example.com" // Extract the actual host from the requestHead
        let port: Int = 443 // Use appropriate port

        bootstrap.connect(host: host, port: port).whenComplete { result in
            switch result {
            case .success(let channel):
                self.targetChannel = channel
                let requestPart = HTTPClientRequestPart.head(requestHead)
                channel.write(NIOAny(requestPart), promise: nil)
            case .failure(let error):
                self.loggingService.log("Failed to connect to target server: \(error)", level: .error)
                self.sendResponse(context: context, status: .badGateway, body: "Failed to connect to target server")
            }
        }
    }

    private func sendResponse(context: ChannelHandlerContext, status: HTTPResponseStatus, body: String) {
        var buffer = context.channel.allocator.buffer(capacity: body.utf8.count)
        buffer.writeString(body)

        let responseHead = HTTPResponseHead(version: .http1_1, status: status)
        context.write(NIOAny(HTTPServerResponsePart.head(responseHead)), promise: nil)
        context.write(NIOAny(HTTPServerResponsePart.body(.byteBuffer(buffer))), promise: nil)
        context.writeAndFlush(NIOAny(HTTPServerResponsePart.end(nil)), promise: nil)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        loggingService.log("SSLHandler encountered error: \(error)", level: .error)
        context.close(promise: nil)
    }
}
