//
//  HTTPServerHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import NIO
import NIOHTTP1

final class HTTPServerHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPServerRequestPart
    typealias OutboundOut = HTTPServerResponsePart

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let requestPart = self.unwrapInboundIn(data)
        switch requestPart {
        case .head(let requestHead):
            print("Received request: \(requestHead.uri)")
            
            // Prepare the response
            let responseHead = HTTPResponseHead(version: requestHead.version, status: .ok)
            context.write(self.wrapOutboundOut(.head(responseHead)), promise: nil)
            
            var buffer = context.channel.allocator.buffer(capacity: 128)
            buffer.writeString("Hello, world!")
            context.write(self.wrapOutboundOut(.body(.byteBuffer(buffer))), promise: nil)
            
            context.writeAndFlush(self.wrapOutboundOut(.end(nil)), promise: nil)
        case .body, .end:
            break
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }
}
