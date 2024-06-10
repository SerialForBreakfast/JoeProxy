import XCTest
import NIO
import NIOHTTP1
import NIOSSL
@testable import JoeProxy


class SSLProxyTests: XCTestCase {
    var certificateService: CertificateService!
    var configurationService: MockConfigurationService!
    var loggingService: MockLoggingService!
    var filteringService: MockFilteringService!
    var networkingService: DefaultNetworkingService!
    var eventLoopGroup: MultiThreadedEventLoopGroup!
    var channel: Channel?

    override func setUpWithError() throws {
        super.setUp()

        configurationService = MockConfigurationService()
        loggingService = MockLoggingService()
        filteringService = MockFilteringService(shouldAllow: true)
        certificateService = CertificateService()
        networkingService = DefaultNetworkingService(
            configurationService: configurationService,
            filteringService: filteringService,
            loggingService: loggingService,
            certificateService: certificateService
        )

        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
//        try? FileManager.default.removeItem(at: certificateService.certificateURL)
//        try? FileManager.default.removeItem(at: certificateService.pemURL)
        let expectation = XCTestExpectation(description: "Server started")
        certificateService.generateCertificate(completion: {
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 10.0)
    }
    
    override func tearDownWithError() throws {
        try FileManager.default.removeItem(atPath: "debugCerts")
        super.tearDown()
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
}
