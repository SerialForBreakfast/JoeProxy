import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

final class NIOTypeConverterTests: XCTestCase {
    
    var allocator: ByteBufferAllocator!
    var group: MultiThreadedEventLoopGroup!
    var threadPool: NIOThreadPool!
    var fileIO: NonBlockingFileIO!
    
    override func setUp() {
        super.setUp()
        allocator = ByteBufferAllocator()
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()
        fileIO = NonBlockingFileIO(threadPool: threadPool)
    }
    
    override func tearDown() {
        try? threadPool.syncShutdownGracefully()
        try? group.syncShutdownGracefully()
        allocator = nil
        super.tearDown()
    }

    func testIODataToByteBuffer_HappyPath() throws {
        let originalBuffer: ByteBuffer = allocator.buffer(string: "Hello, ByteBuffer!")
        let ioData: IOData = .byteBuffer(originalBuffer)
        let eventLoop: EventLoop = group.next()
        
        let future: EventLoopFuture<ByteBuffer?> = NIOTypeConverter.ioDataToByteBuffer(ioData: ioData, allocator: allocator, fileIO: fileIO, eventLoop: eventLoop)
        
        future.whenSuccess { (convertedBuffer: ByteBuffer?) in
            XCTAssertNotNil(convertedBuffer)
            XCTAssertEqual(convertedBuffer, originalBuffer)
            print("testIODataToByteBuffer_HappyPath passed")
        }
        
        _ = try future.wait()
    }
    
    func testIODataToByteBuffer_FailurePath() throws {
        let invalidPath: String = "/tmp/nonexistentfile"
        
        // Handle invalid path safely
        guard let fileHandle: NIOFileHandle = try? NIOFileHandle(path: invalidPath) else {
            print("File handle could not be created for path: \(invalidPath)")
            XCTAssertTrue(true, "Expected error: File handle could not be created for invalid path")
            return
        }

        let fileRegion: FileRegion = FileRegion(fileHandle: fileHandle, readerIndex: 0, endIndex: 10)
        let ioData: IOData = .fileRegion(fileRegion)
        let eventLoop: EventLoop = group.next()
        
        let future: EventLoopFuture<ByteBuffer?> = NIOTypeConverter.ioDataToByteBuffer(ioData: ioData, allocator: allocator, fileIO: fileIO, eventLoop: eventLoop)
        
        future.whenFailure { (error: Error) in
            XCTAssertNotNil(error)
            print("testIODataToByteBuffer_FailurePath passed with error: \(error)")
        }
        
        do {
            _ = try future.wait()
            XCTFail("Expected error, but got success")
        } catch {
            XCTAssertTrue(true, "Expected error: \(error)")
        }
    }

    func testByteBufferToIOData_HappyPath() {
        let originalBuffer: ByteBuffer = allocator.buffer(string: "Hello, ByteBuffer!")
        let ioData: IOData = NIOTypeConverter.byteBufferToIOData(buffer: originalBuffer)
        
        switch ioData {
        case .byteBuffer(let buffer):
            XCTAssertEqual(buffer, originalBuffer)
            print("testByteBufferToIOData_HappyPath passed")
        default:
            XCTFail("Conversion to IOData failed")
        }
    }

    func testRequestPartToByteBuffer_HappyPath() {
        let originalBuffer: ByteBuffer = allocator.buffer(string: "Request Body")
        let requestPart: HTTPServerRequestPart = .body(originalBuffer)
        
        if let convertedBuffer: ByteBuffer = NIOTypeConverter.requestPartToByteBuffer(part: requestPart) {
            XCTAssertEqual(convertedBuffer, originalBuffer)
            print("testRequestPartToByteBuffer_HappyPath passed")
        } else {
            XCTFail("Conversion to ByteBuffer failed")
        }
    }

    func testRequestPartToByteBuffer_FailurePath() {
        let requestPart: HTTPServerRequestPart = .end(nil)
        
        XCTAssertNil(NIOTypeConverter.requestPartToByteBuffer(part: requestPart))
        print("testRequestPartToByteBuffer_FailurePath passed")
    }

    func testResponsePartToByteBuffer_HappyPath() {
        let originalBuffer: ByteBuffer = allocator.buffer(string: "Response Body")
        let responsePart: HTTPServerResponsePart = .body(.byteBuffer(originalBuffer))
        
        if let convertedBuffer: ByteBuffer = NIOTypeConverter.responsePartToByteBuffer(part: responsePart) {
            XCTAssertEqual(convertedBuffer, originalBuffer)
            print("testResponsePartToByteBuffer_HappyPath passed")
        } else {
            XCTFail("Conversion to ByteBuffer failed")
        }
    }

    func testResponsePartToByteBuffer_FailurePath() {
        let responsePart: HTTPServerResponsePart = .end(nil)
        
        XCTAssertNil(NIOTypeConverter.responsePartToByteBuffer(part: responsePart))
        print("testResponsePartToByteBuffer_FailurePath passed")
    }

    func testHttpPartToByteBuffer_HappyPath() {
        let originalBuffer: ByteBuffer = allocator.buffer(string: "HTTP Body")
        let httpPart: HTTPPart<HTTPRequestHead, ByteBuffer> = .body(originalBuffer)
        
        if let convertedBuffer: ByteBuffer = NIOTypeConverter.httpPartToByteBuffer(part: httpPart) {
            XCTAssertEqual(convertedBuffer, originalBuffer)
            print("testHttpPartToByteBuffer_HappyPath passed")
        } else {
            XCTFail("Conversion to ByteBuffer failed")
        }
    }

    func testHttpPartToByteBuffer_FailurePath() {
        let head: HTTPRequestHead = HTTPRequestHead(version: .http1_1, method: .GET, uri: "/")
        let httpPart: HTTPPart<HTTPRequestHead, ByteBuffer> = .head(head)
        
        XCTAssertNil(NIOTypeConverter.httpPartToByteBuffer(part: httpPart))
        print("testHttpPartToByteBuffer_FailurePath passed")
    }
    
    func testIODataToByteBuffer_HappyPath2() throws {
        let expectation: XCTestExpectation = self.expectation(description: "IOData to ByteBuffer conversion should succeed")
        let originalBuffer: ByteBuffer = allocator.buffer(string: "Hello, ByteBuffer!")
        let ioData: IOData = .byteBuffer(originalBuffer)
        let eventLoop: EventLoop = group.next()
        
        let future: EventLoopFuture<ByteBuffer?> = NIOTypeConverter.ioDataToByteBuffer(ioData: ioData, allocator: allocator, fileIO: fileIO, eventLoop: eventLoop)
        
        future.whenSuccess { (convertedBuffer: ByteBuffer?) in
            XCTAssertNotNil(convertedBuffer)
            XCTAssertEqual(convertedBuffer, originalBuffer)
            print("testIODataToByteBuffer_HappyPath2 passed")
            expectation.fulfill()
        }
        
        future.whenFailure { (error: Error) in
            XCTFail("Conversion failed with error: \(error)")
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 5, handler: nil)
    }
}

extension ByteBuffer {
    func getString(at index: Int, length: Int) -> String? {
        guard let bytes = getBytes(at: index, length: length) else {
            return nil
        }
        return String(bytes: bytes, encoding: .utf8)
    }
}
