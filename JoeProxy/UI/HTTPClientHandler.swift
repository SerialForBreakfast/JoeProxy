//
//  HTTPClientHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//
import NIO
import NIOHTTP1

final class HTTPClientHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    private var promise: EventLoopPromise<Void>?
    private var context: ChannelHandlerContext?

    func handlerAdded(context: ChannelHandlerContext) {
        self.promise = context.eventLoop.makePromise(of: Void.self)
        self.context = context
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        let responsePart = self.unwrapInboundIn(data)
        switch responsePart {
        case .head(let responseHead):
            print("Received response: \(responseHead.status)")
        case .body(let byteBuffer):
            if let responseBody = byteBuffer.getString(at: 0, length: byteBuffer.readableBytes) {
                print("Response body: \(responseBody)")
            }
        case .end:
            self.promise?.succeed(())
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("Error: \(error)")
        context.close(promise: nil)
    }

    func waitForResponse() -> EventLoopFuture<Void> {
        return self.promise?.futureResult ?? context!.eventLoop.makeSucceededFuture(())
    }
}
