import NIO
import NIOHTTP1

final class HTTPServerPipelineHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = HTTPServerResponsePart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        // Use unwrapInboundIn to convert NIOAny to HTTPServerRequestPart
        let requestPart = self.unwrapInboundIn(data)
        print("channelRead - requestPart: \(requestPart), type: \(type(of: requestPart))")

        switch requestPart {
        case .head(let request):
            print("Received request head: \(request), type: \(type(of: request))")
        case .body(let buffer):
            let bodyContent: String? = buffer.getString(at: 0, length: buffer.readableBytes)
            print("Received request body: \(bodyContent ?? ""), type: \(type(of: buffer))")
        case .end:
            let responseHead = HTTPResponseHead(version: .http1_1, status: .ok)
            print("Creating response head: \(responseHead), type: \(type(of: responseHead))")

            let responseBody = context.channel.allocator.buffer(string: "JoeProxy")
            print("Creating response body: \(responseBody.getString(at: 0, length: responseBody.readableBytes) ?? ""), type: \(type(of: responseBody))")

            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            context.write(self.wrapOutboundOut(.body(.byteBuffer(responseBody))), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    func channelReadComplete(context: ChannelHandlerContext) {
        print("channelReadComplete - flushing context")
        context.flush()
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("errorCaught - error: \(error), type: \(type(of: error))")
        context.close(promise: nil)
    }

    // Static methods for centralized conversion
    static func toHTTPServerRequestPart(buffer: ByteBuffer) -> HTTPServerRequestPart? {
        var tempBuffer = buffer
        let embeddedChannel = EmbeddedChannel()
        let decoder = ByteToMessageHandler(HTTPRequestDecoder())

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
        let responseHead = HTTPResponseHead(version: .http1_1, status: .ok)
        let ioData: IOData = .byteBuffer(buffer)
        return HTTPServerResponsePart.body(ioData)
    }

    static func toIOData(buffer: ByteBuffer) -> IOData {
        return .byteBuffer(buffer)
    }

    static func toByteBuffer(ioData: IOData, allocator: ByteBufferAllocator, fileIO: NonBlockingFileIO, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer?> {
        switch ioData {
        case .byteBuffer(let buffer):
            return eventLoop.makeSucceededFuture(buffer)
        case .fileRegion(let fileRegion):
            return fileIO.read(fileRegion: fileRegion, allocator: allocator, eventLoop: eventLoop).map { $0 }
        }
    }
}
