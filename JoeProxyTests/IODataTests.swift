//
//  IODataTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/10/24.
//

import XCTest
import NIO
@testable import JoeProxy

final class IODataTests: XCTestCase {
    var group: MultiThreadedEventLoopGroup!
    var threadPool: NIOThreadPool!
    var fileIO: NonBlockingFileIO!
    
    override func setUp() {
        super.setUp()
        group = MultiThreadedEventLoopGroup(numberOfThreads: 1)
        threadPool = NIOThreadPool(numberOfThreads: 1)
        threadPool.start()
        fileIO = NonBlockingFileIO(threadPool: threadPool)
    }
    
    override func tearDown() {
        try? threadPool.syncShutdownGracefully()
        try? group.syncShutdownGracefully()
        super.tearDown()
    }
    
    func testByteBufferConversion() throws {
        print("Running testByteBufferConversion...")
        
        let allocator = ByteBufferAllocator()
        let originalBuffer = allocator.buffer(string: "Hello, ByteBuffer!")
        let ioData: IOData = .byteBuffer(originalBuffer)
        let eventLoop = group.next()
        
        let future = ioData.toByteBuffer(allocator: allocator, fileIO: fileIO, eventLoop: eventLoop)
        
        future.whenSuccess { convertedBuffer in
            guard let convertedBuffer = convertedBuffer else {
                XCTFail("Conversion to ByteBuffer failed")
                return
            }
            
            XCTAssertEqual(convertedBuffer, originalBuffer)
            print("Original and converted ByteBuffer are equal.")
        }
        
        try future.wait()
    }
    
    func testFileRegionConversion() throws {
        print("Running testFileRegionConversion...")
        
        let allocator = ByteBufferAllocator()
        let content = "Hello, FileRegion!"
        let filePath = "/tmp/testFileRegion.txt"
        
        // Write content to file
        try content.write(toFile: filePath, atomically: true, encoding: .utf8)
        
        let fileHandle = try NIOFileHandle(path: filePath)
        let fileRegion = FileRegion(fileHandle: fileHandle, readerIndex: 0, endIndex: content.count)
        let ioData: IOData = .fileRegion(fileRegion)
        let eventLoop = group.next()
        
        let future = ioData.toByteBuffer(allocator: allocator, fileIO: fileIO, eventLoop: eventLoop)
        
        future.whenSuccess { convertedBuffer in
            guard let convertedBuffer = convertedBuffer else {
                XCTFail("Conversion to ByteBuffer failed")
                return
            }
            
            XCTAssertEqual(convertedBuffer.getString(at: 0, length: content.count), content)
            print("Original file content and converted ByteBuffer content are equal.")
        }
        
        // Clean up
        try future.wait()
        try fileHandle.close()
        try FileManager.default.removeItem(atPath: filePath)
    }
}
