import NIO
import NIOHTTP1

class HTTPServerPipelineHandler: ChannelInboundHandler, ChannelOutboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias InboundOut = ByteBuffer
    typealias OutboundIn = HTTPServerResponsePart
    typealias OutboundOut = ByteBuffer

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart: HTTPServerRequestPart = unwrapInboundIn(data)
        switch requestPart {
        case .head(let request):
            print("Received request head: \(request)")
        case .body(let buffer):
            print("Received request body: \(buffer.getString(at: 0, length: buffer.readableBytes) ?? "")")
        case .end:
            let responseHead: HTTPResponseHead = HTTPResponseHead(version: .http1_1, status: .ok)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            let responseBody: ByteBuffer = context.channel.allocator.buffer(string: "Hello, world!")
            context.write(self.wrapOutboundOut(.body(.byteBuffer(responseBody))), promise: nil)
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        }
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
        let responsePart: HTTPServerResponsePart = unwrapOutboundIn(data)
        context.write(self.wrapOutboundOut(responsePart), promise: promise)
    }

    func unwrapOutboundIn(_ data: NIOAny) -> HTTPServerResponsePart {
        let inboundData: ByteBuffer = unwrapInboundIn(data)
        print("unwrapOutboundIn data of type: \(type(of: data)) unwrapInboundIn(data) \(type(of: inboundData))")
        let returnData: HTTPPart<HTTPResponseHead, IOData> = HTTPServerResponsePart.body(.byteBuffer(inboundData))
        return returnData
    }

    func wrapOutboundOut(_ data: HTTPServerResponsePart) -> NIOAny {
        print("wrapOutboundOut data of type: \(type(of: data))")
        switch data {
        case .head(let responseHead):
            return NIOAny(HTTPServerResponsePart.head(responseHead))
        case .body(let ioData):
            return NIOAny(HTTPServerResponsePart.body(ioData))
        case .end(let headers):
            return NIOAny(HTTPServerResponsePart.end(headers))
        }
    }

    // Helper methods for wrapping/unwrapping NIOAny
    func unwrapInboundIn(_ data: NIOAny) -> ByteBuffer {
        guard let buffer = data as? ByteBuffer else {
            fatalError("Expected ByteBuffer but got \(type(of: data))")
        }
        print("unwrapInboundIn returning ByteBuffer of type: \(type(of: buffer))")
        return buffer
    }
    
    func wrapInboundOut(_ data: HTTPPart<HTTPRequestHead, ByteBuffer>) -> NIOAny {
        print("wrapInboundOut wrapping HTTPPart<HTTPRequestHead, ByteBuffer> of type: \(type(of: data))")
        return NIOAny(data)
    }
}

enum NIOHTTPDecoderError: Error {
    case invalidData
}

//extension HTTPServerRequestPart {
//    init(from buffer: inout ByteBuffer) throws {
//        let decoder = HTTPRequestDecoder(leftOverBytesStrategy: .forwardBytes)
//        var handler = ByteToMessageHandler(decoder)
//        let context = ChannelHandlerContextMock()
//        try handler.decode(context: context, buffer: &buffer)
//        
//        guard let part = context.readInbound() else {
//            throw NIOHTTPDecoderError.invalidData
//        }
//        
//        self = part
//    }
//}
//
//// Mock to simulate ChannelHandlerContext for decoding
//final class ChannelHandlerContextMock: ChannelHandlerContext {
//    private var inboundBuffer: [HTTPServerRequestPart] = []
//    
//    func readInbound() -> HTTPServerRequestPart? {
//        return inboundBuffer.first
//    }
//    
//    func fireChannelRead(_ data: NIOAny) {
//        if let part = data as? HTTPServerRequestPart {
//            inboundBuffer.append(part)
//        }
//    }
//    
//    // Implement other required methods for protocol conformance...
//}
