import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

class NIOConverterTests: XCTestCase {
    
    func testHttpRequestPartToByteBuffer() {
        let allocator = ByteBufferAllocator()
        let headers = HTTPHeaders([("Host", "localhost")])
        let requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1), method: .GET, uri: "/", headers: headers)
        let requestPart = HTTPServerRequestPart.head(requestHead)
        
        let buffer = NIOConverter.httpRequestPartToByteBuffer(requestPart, allocator: allocator)
        XCTAssertTrue(buffer.getString(at: 0, length: buffer.readableBytes)!.contains("GET / HTTP/1.1"))
    }
    
    func testByteBufferToHTTPRequestPart() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 256)
        buffer.writeString("GET / HTTP/1.1\r\nHost: localhost\r\n\r\n")
        
        let requestPart = try NIOConverter.byteBufferToHTTPRequestPart(&buffer)
        print("Type of requestPart: \(type(of: requestPart))")
        if case .head(let requestHead) = requestPart {
            XCTAssertEqual(requestHead.method, HTTPMethod.GET)
            XCTAssertEqual(requestHead.uri, "/")
            XCTAssertEqual(requestHead.headers["Host"].first, "localhost")
        } else {
            XCTFail("Expected HTTPRequestHead but got \(requestPart)")
        }
    }
    
    func testHttpResponsePartToByteBuffer() {
        let allocator = ByteBufferAllocator()
        let headers = HTTPHeaders([("Content-Type", "text/plain")])
        let responseHead = HTTPResponseHead(version: HTTPVersion(major: 1, minor: 1), status: .ok, headers: headers)
        let responsePart = HTTPServerResponsePart.head(responseHead)
        do {
            let buffer = try NIOConverter.httpResponsePartToByteBuffer(responsePart, allocator: allocator, fileIO: NonBlockingFileIO(threadPool: NIOThreadPool(numberOfThreads: 1)), eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next()).wait()
            XCTAssertTrue(buffer.getString(at: 0, length: buffer.readableBytes)!.contains("HTTP/1.1 200 OK"))
        } catch {
            XCTFail()
        }
        
    }
    
    func testByteBufferToHTTPResponsePart() throws {
        var buffer = ByteBufferAllocator().buffer(capacity: 256)
        buffer.writeString("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n")
        
        let responsePart = try NIOConverter.byteBufferToHTTPResponsePart(&buffer)
        print("Type of responsePart: \(type(of: responsePart))")
        if case .head(let responseHead) = responsePart {
            XCTAssertEqual(responseHead.status, HTTPResponseStatus.ok)
            XCTAssertEqual(responseHead.headers["Content-Type"].first, "text/plain")
        } else {
            XCTFail("Expected HTTPResponseHead but got \(responsePart)")
        }
    }
}
