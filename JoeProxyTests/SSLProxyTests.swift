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

//    func testServerStop() throws {
//        let startExpectation = XCTestExpectation(description: "Server started")
//        
//        try networkingService.startServer { [weak self] result in
//            guard let self = self else { return }
//            switch result {
//            case .success:
//                self.serverChannel = self.networkingService.channel
//                startExpectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to start server: \(error)")
//            }
//        }
//        
//        wait(for: [startExpectation], timeout: 10.0)
//        
//        let stopExpectation = XCTestExpectation(description: "Server stopped")
//        networkingService.stopServer { result in
//            switch result {
//            case .success:
//                stopExpectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to stop server: \(error)")
//            }
//        }
//        
//        wait(for: [stopExpectation], timeout: 10.0)
//    }
}



//    func testSSLProxyWithCurl() throws {
//        let expectation = XCTestExpectation(description: "Server started")
//        
//        try networkingService.startServer { result in
//            switch result {
//            case .success:
//                print("Server started successfully.")
//                expectation.fulfill()
//            case .failure(let error):
//                XCTFail("Failed to start server: \(error)")
//            }
//        }
//        
//        wait(for: [expectation], timeout: 10.0)
//        
//        let curlTask = Process()
//        curlTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
//        curlTask.arguments = ["-k", "https://localhost:8443"]
//        
//        let pipe = Pipe()
//        curlTask.standardOutput = pipe
//        curlTask.standardError = pipe
//        
//        try curlTask.run()
//        curlTask.waitUntilExit()
//        
//        let data = pipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: data, encoding: .utf8)
//        
//        XCTAssertEqual(curlTask.terminationStatus, 0, "Curl command failed with exit code \(curlTask.terminationStatus)")
//        XCTAssertTrue(output?.contains("JoeProxy") ?? false, "Curl output did not contain expected content. Output: \(output ?? "")")
//    }
//}
