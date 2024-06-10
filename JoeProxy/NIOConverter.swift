import NIO
import NIOHTTP1

enum NIOConverterError: Error {
    case invalidData
}

class NIOConverter {
    static func byteBufferToHTTPRequestPart(_ buffer: inout ByteBuffer) throws -> HTTPServerRequestPart {
        guard let requestLine = buffer.readString(length: buffer.readableBytes) else {
            throw NIOConverterError.invalidData
        }
        
        let requestComponents = requestLine.split(separator: "\r\n")
        guard let statusLine = requestComponents.first?.split(separator: " "),
              statusLine.count >= 3 else {
            throw NIOConverterError.invalidData
        }
        let method = HTTPMethod(rawValue: String(statusLine[0]))
        
        let uri = String(statusLine[1])
        let version = HTTPVersion(major: 1, minor: 1)
        var headers = HTTPHeaders()
        
        for headerLine in requestComponents.dropFirst() {
            let headerParts = headerLine.split(separator: ": ", maxSplits: 1)
            if headerParts.count == 2 {
                headers.add(name: String(headerParts[0]), value: String(headerParts[1]))
            }
        }
        
        let requestHead = HTTPRequestHead(version: version, method: method, uri: uri, headers: headers)
        let requestPart = HTTPServerRequestPart.head(requestHead)
        print("Type of requestPart: \(type(of: requestPart))")
        return requestPart
    }
    
    static func byteBufferToHTTPResponsePart(_ buffer: inout ByteBuffer) throws -> HTTPServerResponsePart {
        guard let responseLine = buffer.readString(length: buffer.readableBytes) else {
            throw NIOConverterError.invalidData
        }
        
        let responseComponents = responseLine.split(separator: "\r\n")
        guard let statusLine = responseComponents.first?.split(separator: " "),
              statusLine.count >= 3 else {
            throw NIOConverterError.invalidData
        }
        
        let statusCode = Int(statusLine[1]) ?? 200
        let status = HTTPResponseStatus(statusCode: statusCode)
        var headers = HTTPHeaders()
        
        for headerLine in responseComponents.dropFirst() {
            let headerParts = headerLine.split(separator: ": ", maxSplits: 1)
            if headerParts.count == 2 {
                headers.add(name: String(headerParts[0]), value: String(headerParts[1]))
            }
        }
        
        let responseHead = HTTPResponseHead(version: HTTPVersion(major: 1, minor: 1), status: status, headers: headers)
        let responsePart = HTTPServerResponsePart.head(responseHead)
        print("Type of responsePart: \(type(of: responsePart))")
        return responsePart
    }
    
    static func httpRequestPartToByteBuffer(_ part: HTTPServerRequestPart, allocator: ByteBufferAllocator) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 256)
        
        switch part {
        case .head(let requestHead):
            buffer.writeString("\(requestHead.method) \(requestHead.uri) HTTP/\(requestHead.version.major).\(requestHead.version.minor)\r\n")
            requestHead.headers.forEach { header in
                buffer.writeString("\(header.name): \(header.value)\r\n")
            }
            buffer.writeString("\r\n")
        case .body(var body):
            print("Type of body: \(type(of: body))")
            buffer.writeBuffer(&body)
        case .end:
            break
        }
        return buffer
    }
    
    static func httpResponsePartToByteBuffer(_ part: HTTPServerResponsePart, allocator: ByteBufferAllocator, fileIO: NonBlockingFileIO, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
        var buffer = allocator.buffer(capacity: 256)
        
        switch part {
        case .head(let responseHead):
            buffer.writeString("HTTP/\(responseHead.version.major).\(responseHead.version.minor) \(responseHead.status.code) \(responseHead.status.reasonPhrase)\r\n")
            responseHead.headers.forEach { header in
                buffer.writeString("\(header.name): \(header.value)\r\n")
            }
            buffer.writeString("\r\n")
            return eventLoop.makeSucceededFuture(buffer)
        case .body(let body):
            print("Type of body: \(type(of: body))")
            return body.toByteBuffer(allocator: allocator, fileIO: fileIO, eventLoop: eventLoop).map { byteBuffer in
                var buffer = allocator.buffer(capacity: 256)
                if var byteBuffer = byteBuffer {
                    buffer.writeBuffer(&byteBuffer)
                }
                return buffer
            }
        case .end:
            return eventLoop.makeSucceededFuture(buffer)
        }
    }
}

extension IOData {
    func toByteBuffer(allocator: ByteBufferAllocator, fileIO: NonBlockingFileIO, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer?> {
        switch self {
        case .byteBuffer(let byteBuffer):
            return eventLoop.makeSucceededFuture(byteBuffer)
        case .fileRegion(let fileRegion):
            return fileIO.read(fileRegion: fileRegion, allocator: allocator, eventLoop: eventLoop).map { $0 as ByteBuffer? }
        }
    }
}
