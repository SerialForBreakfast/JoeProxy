//
//  NIOAny+Extensions.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/10/24.
//
import NIO
import NIOHTTP1

extension NIOAny {
    func tryAsHTTPServerRequestPart() -> HTTPServerRequestPart? {
        // Check if already HTTPServerRequestPart
        if let part = self.unwrap(as: HTTPServerRequestPart.self) {
            return part
        }
        
        // Convert ByteBuffer to HTTPServerRequestPart
        if let buffer = self.tryAsByteBuffer() {
            return HTTPServerPipelineHandler.toHTTPServerRequestPart(buffer: buffer)
        }
        
        return nil
    }
    
    func tryAsHTTPServerResponsePart() -> HTTPServerResponsePart? {
        // Check if already HTTPServerResponsePart
        if let part = self.unwrap(as: HTTPServerResponsePart.self) {
            return part
        }
        
        // Convert ByteBuffer to HTTPServerResponsePart
        if let buffer = self.tryAsByteBuffer() {
            return HTTPServerPipelineHandler.toHTTPServerResponsePart(buffer: buffer)
        }
        
        return nil
    }

    func tryAsByteBuffer() -> ByteBuffer? {
        // Attempt to cast directly to ByteBuffer
        if let buffer = self.unwrap(as: ByteBuffer.self) {
            return buffer
        }
        
        // Attempt to extract ByteBuffer from HTTPServerRequestPart
        if let requestPart = self.unwrap(as: HTTPServerRequestPart.self) {
            switch requestPart {
            case .body(let buffer):
                return buffer
            default:
                return nil
            }
        }
        
        // Attempt to extract ByteBuffer from HTTPServerResponsePart
        if let responsePart = self.unwrap(as: HTTPServerResponsePart.self) {
            switch responsePart {
            case .body(let ioData):
                if case let .byteBuffer(buffer) = ioData {
                    return buffer
                }
                return nil
            default:
                return nil
            }
        }
        
        return nil
    }
    
    // Helper method to unwrap NIOAny to a specific type
    func unwrap<T>(as type: T.Type) -> T? {
        if let value = self as? T {
            return value
        }
        return nil
    }
}
