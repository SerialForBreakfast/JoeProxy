//
//  SSLHandler.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/7/24.
//

import NIO
import NIOHTTP1
import NIOSSL

final class SSLHandler: ChannelInboundHandler {
    typealias InboundIn = ByteBuffer
    typealias OutboundOut = ByteBuffer

    private let filteringService: FilteringService
    private let loggingService: LoggingService

    init(filteringService: FilteringService, loggingService: LoggingService) {
        self.filteringService = filteringService
        self.loggingService = loggingService
    }

    func channelRead(context: ChannelHandlerContext, data: NIOAny) {
        var buffer = self.unwrapInboundIn(data)
        if let request = buffer.readString(length: buffer.readableBytes) {
            print("Decrypted request: \(request)")
            // Forward the decrypted request to SimpleHandler
            context.fireChannelRead(data)
        } else {
            print("Failed to read decrypted request.")
        }
    }

    func errorCaught(context: ChannelHandlerContext, error: Error) {
        print("SSLHandler encountered error: \(error)")
        context.close(promise: nil)
    }
}
