//
//  HTTPServerPipelineHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/9/24.
//

import NIO
import NIOHTTP1

final class HTTPServerPipelineHandler: ChannelDuplexHandler {
    typealias InboundIn = ByteBuffer
    typealias InboundOut = HTTPServerRequestPart
    typealias OutboundIn = HTTPServerResponsePart
    typealias OutboundOut = ByteBuffer

    private var requestBuffer: ByteBuffer?
    
    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        
        while buffer.readableBytes > 0 {
                   guard let part = try? NIOConverter.byteBufferToHTTPRequestPart(&buffer) else {
                       context.fireErrorCaught(NIOConverterError.invalidData)
                       return
                   }
                   
            switch part {
            case .head(let head):
                context.fireChannelRead(self.wrapInboundOut(.head(head)))
            case .body(let body):
                context.fireChannelRead(self.wrapInboundOut(.body(body)))
            case .end:
                context.fireChannelRead(self.wrapInboundOut(.end(nil)))
            }
        }
    }

    func write(context: ChannelHandlerContext, data: NIOAny, promise: EventLoopPromise<Void>?) {
//        let part = self.unwrapOutboundIn(data)
//        
//        switch part {
//        case .head(let head):
//            var buffer = context.channel.allocator.buffer(capacity: 128)
//            buffer.writeString("HTTP/1.1 \(head.status.code) \(head.status.reasonPhrase)\r\n")
//            for (name, value) in head.headers {
//                buffer.writeString("\(name): \(value)\r\n")
//            }
//            buffer.writeString("\r\n")
//            context.write(self.wrapOutboundOut(buffer), promise: promise)
//        case .body(let body):
//            context.write(self.wrapOutboundOut(body), promise: promise)
//        case .end:
//            var buffer = context.channel.allocator.buffer(capacity: 64)
//            buffer.writeString("\r\n")
//            context.write(self.wrapOutboundOut(buffer), promise: promise)
//            context.flush()
//        }
        var buffer = unwrapInboundIn(data)
        
        do {
            let responsePart = try NIOConverter.byteBufferToHTTPResponsePart(&buffer)
            let responseBuffer = NIOConverter.httpResponsePartToByteBuffer(responsePart, allocator: context.channel.allocator)
            context.write(wrapOutboundOut(responseBuffer), promise: promise)
        } catch {
            context.fireErrorCaught(error)
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        context.fireErrorCaught(error)
    }
}
