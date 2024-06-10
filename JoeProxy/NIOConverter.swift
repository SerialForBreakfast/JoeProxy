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
        return .head(requestHead)
    }

    static func byteBufferToHTTPResponsePart(_ buffer: inout ByteBuffer) throws -> HTTPServerResponsePart {
        guard let responseLine = buffer.readString(length: buffer.readableBytes) else {
            throw NIOConverterError.invalidData
        }
        
        let responseComponents = responseLine.split(separator: "\r\n")
        guard let statusLine = responseComponents.first?.split(separator: " "),
              statusLine.count >= 3,
              let statusCode = Int(statusLine[1]) else {
            throw NIOConverterError.invalidData
        }
        let status = HTTPResponseStatus(statusCode: statusCode)
        
        var headers = HTTPHeaders()
        
        for headerLine in responseComponents.dropFirst() {
            let headerParts = headerLine.split(separator: ": ", maxSplits: 1)
            if headerParts.count == 2 {
                headers.add(name: String(headerParts[0]), value: String(headerParts[1]))
            }
        }
        
        let responseHead = HTTPResponseHead(version: HTTPVersion(major: 1, minor: 1), status: status, headers: headers)
        return .head(responseHead)
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
            buffer.writeBuffer(&body)
        case .end:
            break
        }
        return buffer
    }

    static func httpResponsePartToByteBuffer(_ part: HTTPServerResponsePart, allocator: ByteBufferAllocator) -> ByteBuffer {
        var buffer = allocator.buffer(capacity: 256)
        
        switch part {
        case .head(let responseHead):
            buffer.writeString("HTTP/\(responseHead.version.major).\(responseHead.version.minor) \(responseHead.status.code) \(responseHead.status.reasonPhrase)\r\n")
            responseHead.headers.forEach { header in
                buffer.writeString("\(header.name): \(header.value)\r\n")
            }
            buffer.writeString("\r\n")
        case .body(let body):
            print("Type of body: \(type(of: body))")
            
            switch body {
            case .byteBuffer(var byteBuffer):
                buffer.writeBuffer(&byteBuffer)
            case .fileRegion:
                // Handle file region if needed
                break
            }
        case .end:
            break
        }
        return buffer
    }
}
