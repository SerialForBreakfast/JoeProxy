import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

final class SSLProxyTests: XCTestCase {
    var configurationService: MockConfigurationService!
    var loggingService: MockLoggingService!
    var filteringService: MockFilteringService!
    var certificateService: CertificateService!
    var networkingService: DefaultNetworkingService!
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var fileIO: NonBlockingFileIO!
    private var internalThreadPool: NIOThreadPool!
    private var serverChannel: Channel?

    override func setUpWithError() throws {
        super.setUp()

        configurationService = MockConfigurationService()
        loggingService = MockLoggingService()
        filteringService = MockFilteringService(shouldAllow: true)
        certificateService = CertificateService()
        
        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
        internalThreadPool = NIOThreadPool(numberOfThreads: 2)
        internalThreadPool.start()
        fileIO = NonBlockingFileIO(threadPool: internalThreadPool)

        networkingService = DefaultNetworkingService(
            configurationService: configurationService,
            filteringService: filteringService,
            loggingService: loggingService,
            certificateService: certificateService,
            fileIO: fileIO
        )

        let expectation = XCTestExpectation(description: "Certificate generated")
        certificateService.generateCertificate {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    override func tearDownWithError() throws {
        if let channel = serverChannel {
            try channel.close().wait()
        }
        try internalThreadPool.syncShutdownGracefully()
        try eventLoopGroup.syncShutdownGracefully()
        try super.tearDownWithError()
    }

    func testServerStart() throws {
        let expectation = XCTestExpectation(description: "Server started")
        
        try networkingService.startServer { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success:
                self.serverChannel = self.networkingService.channel
                expectation.fulfill()
            case .failure(let error):
                XCTFail("Failed to start server: \(error)")
            }
        }
        
        wait(for: [expectation], timeout: 10.0)
    }

    func testServerStop() throws {
        // Start the server and check the result synchronously
        let startResult = try startServerSync()
        switch startResult {
        case .success:
            print("Server started successfully")
        case .failure(let error):
            XCTFail("Failed to start server: \(error)")
            return
        }
        
        // Stop the server and check the result synchronously
        let stopResult = try stopServerSync()
        switch stopResult {
        case .success:
            print("Server stopped successfully")
        case .failure(let error):
            XCTFail("Failed to stop server: \(error)")
        }
    }

    func testSSLProxyWithCurl() throws {
        // Start the server and check the result synchronously
        let startResult: Result<Void, Error> = try startServerSync()
        switch startResult {
        case .success:
            print("Server started successfully")
        case .failure(let error):
            XCTFail("Failed to start server: \(error)")
            return
        }
        
        // Get the dynamically assigned port
        guard let port: Int = networkingService.serverPort else {
            XCTFail("Failed to get the server port")
            return
        }
        
        // Execute curl command to test the server response
        let curlTask: Process = Process()
        curlTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        curlTask.arguments = ["-k", "https://localhost:\(port)"]
        
        let pipe: Pipe = Pipe()
        curlTask.standardOutput = pipe
        curlTask.standardError = pipe
        
        try curlTask.run()
        curlTask.waitUntilExit()
        
        let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String? = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(curlTask.terminationStatus, 0, "Curl command failed with exit code \(curlTask.terminationStatus)")
        XCTAssertTrue(output?.contains("JoeProxy") ?? false, "Curl output did not contain expected content. Output: \(output ?? "")")
        
        // Stop the server and check the result synchronously
        let stopResult: Result<Void, Error> = try stopServerSync()
        switch stopResult {
        case .success:
            print("Server stopped successfully")
        case .failure(let error):
            XCTFail("Failed to stop server: \(error)")
        }
    }

    func startServerSync() throws -> Result<Void, Error> {
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var result: Result<Void, Error> = .failure(NSError(domain: "Unknown", code: 0, userInfo: nil))
        
        try networkingService.startServer { startResult in
            result = startResult
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 10)  // 10 seconds timeout
        return result
    }

    func stopServerSync() throws -> Result<Void, Error> {
        let semaphore: DispatchSemaphore = DispatchSemaphore(value: 0)
        var result: Result<Void, Error> = .failure(NSError(domain: "Unknown", code: 0, userInfo: nil))
        
        networkingService.stopServer { stopResult in
            result = stopResult
            semaphore.signal()
        }
        
        _ = semaphore.wait(timeout: .now() + 10)  // 10 seconds timeout
        return result
    }
}
