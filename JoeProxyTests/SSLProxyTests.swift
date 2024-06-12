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
    private let caBundlePath = "/tmp/cacert.pem"
    
    override func setUpWithError() throws {
        super.setUp()
        
        configurationService = MockConfigurationService()
        loggingService = MockLoggingService()
        filteringService = MockFilteringService(shouldAllow: true)
        certificateService = CertificateService(debug: true)
        
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
        
        if !certificateService.certificateExists {
            print("Generating test certificate")
            let expectation = XCTestExpectation(description: "Certificate generated")
            certificateService.generateCertificate {
                expectation.fulfill()
            }
            wait(for: [expectation], timeout: 10.0)
        } else {
            print("Test certificate already exists")
        }
    }
    
    override func tearDownWithError() throws {
        if let channel = serverChannel {
            try channel.close().wait()
        }
        try internalThreadPool.syncShutdownGracefully()
        try eventLoopGroup.syncShutdownGracefully()
        try super.tearDownWithError()
    }
    
    private func generateTestCertificate() {
        let expectation = XCTestExpectation(description: "Certificate generated")
        certificateService.generateCertificate {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 10.0)
    }
    
    private func openCertificate(_ certURL: URL) {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        process.arguments = [certURL.path]
        
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            XCTFail("Failed to open certificate: \(error)")
        }
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
    
    func testHTTPProxy() throws {
        let startResult: Result<Void, Error> = try startServerSync()
        switch startResult {
        case .success:
            print("Server started successfully")
        case .failure(let error):
            XCTFail("Failed to start server: \(error)")
            return
        }
        
        guard let port: Int = networkingService.serverPort else {
            XCTFail("Failed to get the server port")
            return
        }
        
        let url = URL(string: "http://showblender.com/")!
        let semaphore = DispatchSemaphore(value: 0)
        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            XCTAssertNil(error, "Error should be nil")
            if let response = response as? HTTPURLResponse {
                XCTAssertEqual(response.statusCode, 200, "Response status code should be 200")
            } else {
                XCTFail("Invalid response")
            }
            semaphore.signal()
        }
        
        task.resume()
        _ = semaphore.wait(timeout: .now() + 10)
        
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


// Test case
extension SSLProxyTests {
    private func downloadCABundle() {
        let curlTask = Process()
        curlTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        curlTask.arguments = ["--remote-name", "https://curl.se/ca/cacert.pem", "--output", caBundlePath]
        
        let pipe = Pipe()
        curlTask.standardOutput = pipe
        curlTask.standardError = pipe
        
        do {
            try curlTask.run()
            curlTask.waitUntilExit()
            if curlTask.terminationStatus != 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8) ?? "Unknown error"
                XCTFail("Failed to download CA bundle. Output: \(output)")
            }
        } catch {
            XCTFail("Failed to run curl to download CA bundle: \(error)")
        }
    }
    
    func testProxyUsingHttpBin() throws {
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
        
        // Download the CA bundle
        downloadCABundle()
        
        // Check if CA bundle was downloaded
        guard FileManager.default.fileExists(atPath: caBundlePath) else {
            XCTFail("Failed to download CA bundle")
            return
        }
        
        // Combine the CA bundle with our CA certificate
        let combinedCAPath = "/tmp/combined-cacert.pem"
        do {
            let caBundleData = try Data(contentsOf: URL(fileURLWithPath: caBundlePath))
            let ourCAData = try Data(contentsOf: certificateService.certificateURL)
            var combinedData = caBundleData
            combinedData.append(ourCAData)
            try combinedData.write(to: URL(fileURLWithPath: combinedCAPath))
        } catch {
            XCTFail("Failed to combine CA bundle with our CA certificate: \(error)")
            return
        }
        
        // Execute curl command to test the server response
        let curlTask: Process = Process()
        curlTask.executableURL = URL(fileURLWithPath: "/usr/bin/curl")
        curlTask.arguments = [
            "--proxy", "https://localhost:\(port)",
            "--cacert", combinedCAPath,
            "https://httpbin.org/get"
        ]
        
        let pipe: Pipe = Pipe()
        curlTask.standardOutput = pipe
        curlTask.standardError = pipe
        
        try curlTask.run()
        curlTask.waitUntilExit()
        
        let data: Data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output: String? = String(data: data, encoding: .utf8)
        
        XCTAssertEqual(curlTask.terminationStatus, 0, "Curl command failed with exit code \(curlTask.terminationStatus)")
        XCTAssertNotNil(output, "Curl output is nil")
        XCTAssertTrue(output?.contains("\"url\": \"https://httpbin.org/get\"") ?? false, "Curl output did not contain expected content. Output: \(output ?? "")")
        
        // Stop the server and check the result synchronously
        let stopResult: Result<Void, Error> = try stopServerSync()
        switch stopResult {
        case .success:
            print("Server stopped successfully")
        case .failure(let error):
            XCTFail("Failed to stop server: \(error)")
        }
    }
    
    private func appendSelfSignedCertToCABundle() {
        let fileManager = FileManager.default
        let certPath = certificateService.certificateURL.path
        
        guard let certData = try? Data(contentsOf: URL(fileURLWithPath: certPath)) else {
            XCTFail("Failed to read self-signed certificate")
            return
        }
        
        if let fileHandle = FileHandle(forWritingAtPath: caBundlePath) {
            fileHandle.seekToEndOfFile()
            fileHandle.write(certData)
            fileHandle.closeFile()
        } else {
            XCTFail("Failed to open CA bundle for writing")
        }
    }
}
