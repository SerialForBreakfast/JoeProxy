import NIO
import NIOHTTP1

class NIOTypeConverter {
    static func ioDataToByteBuffer(ioData: IOData, allocator: ByteBufferAllocator, fileIO: NonBlockingFileIO, eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer?> {
        switch ioData {
        case .byteBuffer(let byteBuffer):
            return eventLoop.makeSucceededFuture(byteBuffer)
        case .fileRegion(let fileRegion):
            return fileIO.read(fileRegion: fileRegion, allocator: allocator, eventLoop: eventLoop).map { $0 as ByteBuffer? }
        }
    }

    static func byteBufferToIOData(buffer: ByteBuffer) -> IOData {
        return .byteBuffer(buffer)
    }

    static func requestPartToByteBuffer(part: HTTPServerRequestPart) -> ByteBuffer? {
        switch part {
        case .body(let buffer):
            return buffer
        default:
            return nil
        }
    }

    static func responsePartToByteBuffer(part: HTTPServerResponsePart) -> ByteBuffer? {
        switch part {
        case .body(let ioData):
            do {
                return try ioData.toByteBuffer(allocator: ByteBufferAllocator(), fileIO: NonBlockingFileIO(threadPool: NIOThreadPool(numberOfThreads: 1)), eventLoop: MultiThreadedEventLoopGroup(numberOfThreads: 1).next()).wait()
            } catch {
                print("Failed to convert IOData to ByteBuffer: \(error)")
                return nil
            }
        default:
            return nil
        }
    }

    static func byteBufferToRequestPart(buffer: ByteBuffer) -> HTTPServerRequestPart {
        return .body(buffer)
    }

    static func byteBufferToResponsePart(buffer: ByteBuffer) -> HTTPServerResponsePart {
        return .body(.byteBuffer(buffer))
    }

    static func httpPartToByteBuffer(part: HTTPPart<HTTPRequestHead, ByteBuffer>) -> ByteBuffer? {
        switch part {
        case .body(let buffer):
            return buffer
        default:
            return nil
        }
    }

    static func byteBufferToHttpPart(buffer: ByteBuffer) -> HTTPPart<HTTPRequestHead, ByteBuffer> {
        return .body(buffer)
    }

    static func httpPartToIOData(part: HTTPPart<HTTPRequestHead, ByteBuffer>) -> IOData? {
        switch part {
        case .body(let buffer):
            return .byteBuffer(buffer)
        default:
            return nil
        }
    }

    static func ioDataToHttpPart(ioData: IOData) -> HTTPPart<HTTPRequestHead, ByteBuffer>? {
        switch ioData {
        case .byteBuffer(let buffer):
            return .body(buffer)
        case .fileRegion:
            return nil
        }
    }
}
