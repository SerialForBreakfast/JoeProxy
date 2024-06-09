import NIO
import NIOHTTP1

final class HTTPClientResponseHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    typealias OutboundOut = HTTPServerResponsePart

    private let serverContext: ChannelHandlerContext

    init(serverContext: ChannelHandlerContext) {
        self.serverContext = serverContext
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let part = unwrapInboundIn(data)
        switch part {
        case .head(let responseHead):
            handleResponseHead(context: context, responseHead: responseHead)
        case .body(let responseBody):
            handleResponseBody(context: context, responseBody: responseBody)
        case .end:
            handleResponseEnd(context: context)
        }
    }

    private func handleResponseHead(context: ChannelHandlerContext, responseHead: HTTPResponseHead) {
        var headers = HTTPHeaders()
        responseHead.headers.forEach { headers.add(name: $0.name, value: $0.value) }
        let head = HTTPServerResponsePart.head(HTTPResponseHead(version: responseHead.version, status: responseHead.status, headers: headers))
        serverContext.writeAndFlush(NIOAny(head), promise: nil)
    }

    private func handleResponseBody(context: ChannelHandlerContext, responseBody: ByteBuffer) {
        let body = HTTPServerResponsePart.body(.byteBuffer(responseBody))
        serverContext.writeAndFlush(NIOAny(body), promise: nil)
    }

    private func handleResponseEnd(context: ChannelHandlerContext) {
        let end = HTTPServerResponsePart.end(nil)
        serverContext.writeAndFlush(NIOAny(end), promise: nil)
        serverContext.close(promise: nil)
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        serverContext.close(promise: nil)
    }
}
