import NIO
import NIOHTTP1

final class HTTPServerPipelineHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = HTTPServerResponsePart
    typealias OutboundOut = HTTPServerResponsePart

    private let loggingService: LoggingService

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart: HTTPServerRequestPart = self.unwrapInboundIn(data)
        print("channelRead - requestPart: \(requestPart), type: \(type(of: requestPart))")

        switch requestPart {
        case .head(let request):
            self.logRequestHead(request)
        case .body(let buffer):
            self.logRequestBody(buffer)
        case .end:
            self.sendResponse(context: context)
        default:
            print("Received unknown part: \(requestPart), type: \(type(of: requestPart))")
        }
    }

    private func logRequestHead(_ request: HTTPRequestHead) {
        let method: HTTPMethod = request.method
        let uri: String = request.uri
        let headers: HTTPHeaders = request.headers

        self.loggingService.log("Received request head: \(method) \(uri), headers: \(headers)", level: .info)
        print("logRequestHead - method: \(method), uri: \(uri), headers: \(headers)")
    }

    private func logRequestBody(_ buffer: ByteBuffer) {
        let body: String? = buffer.getString(at: 0, length: buffer.readableBytes)
        if let body: String = body {
            self.loggingService.log("Received request body: \(body)", level: .info)
            print("logRequestBody - body: \(body)")
        }
    }

    private func sendResponse(context: ChannelHandlerContext) {
        let responseHead: HTTPResponseHead = HTTPResponseHead(version: .http1_1, status: .ok)
        let responseBody: ByteBuffer = context.channel.allocator.buffer(string: "JoeProxy")

        self.logResponse(responseHead: responseHead, body: responseBody)

        context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
        context.write(self.wrapOutboundOut(.body(.byteBuffer(responseBody))), promise: nil)
        context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
    }

    private func logResponse(responseHead: HTTPResponseHead, body: ByteBuffer) {
        let responseBody: String? = body.getString(at: 0, length: body.readableBytes)
        if let responseBody: String = responseBody {
            self.loggingService.log("Sending response head: \(responseHead.status), headers: \(responseHead.headers)", level: .info)
            self.loggingService.log("Sending response body: \(responseBody)", level: .info)
            print("logResponse - status: \(responseHead.status), headers: \(responseHead.headers), body: \(responseBody)")
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        print("channelReadComplete - flushing context")
        context.flush()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        self.loggingService.log("Error: \(error)", level: .error)
        print("errorCaught - error: \(error), type: \(type(of: error))")
        context.close(promise: nil)
    }
}

extension HTTPServerPipelineHandler {
    static func toHTTPServerRequestPart(buffer: ByteBuffer) -> HTTPServerRequestPart? {
        var tempBuffer: ByteBuffer = buffer
        let embeddedChannel: EmbeddedChannel = EmbeddedChannel()
        let decoder: ByteToMessageHandler<HTTPRequestDecoder> = ByteToMessageHandler(HTTPRequestDecoder())

        do {
            try embeddedChannel.pipeline.addHandler(decoder).wait()
            try embeddedChannel.writeInbound(tempBuffer)
            return try embeddedChannel.readInbound()
        } catch {
            print("Error decoding HTTP request part: \(error)")
            return nil
        }
    }

    static func toHTTPServerResponsePart(buffer: ByteBuffer) -> HTTPServerResponsePart {
        let responseHead: HTTPResponseHead = HTTPResponseHead(version: .http1_1, status: .ok)
        let ioData: IOData = .byteBuffer(buffer)
        return HTTPServerResponsePart.body(ioData)
    }
}
