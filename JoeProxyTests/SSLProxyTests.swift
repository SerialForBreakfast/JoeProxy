//
//  SSLProxyTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/9/24.
//
//import XCTest
//import NIO
//@testable import JoeProxy
//
//class SSLProxyTests: XCTestCase {
//    var certificateService: CertificateService!
//    var configurationService: MockConfigurationService!
//    var loggingService: MockLoggingService!
//    var filteringService: MockFilteringService!
//    var networkingService: DefaultNetworkingService!
//    var eventLoopGroup: MultiThreadedEventLoopGroup!
//    var channel: Channel?
//    
//    override func setUpWithError() throws {
//        super.setUp()
//        
//        configurationService = MockConfigurationService()
//        loggingService = MockLoggingService()
//        filteringService = MockFilteringService(shouldAllow: true)
//        certificateService = CertificateService()
//        networkingService = DefaultNetworkingService(
//            configurationService: configurationService,
//            filteringService: filteringService,
//            loggingService: loggingService,
//            certificateService: certificateService
//        )
//        
//        eventLoopGroup = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)
//        try? FileManager.default.removeItem(at: certificateService.certificateURL)
//        try? FileManager.default.removeItem(at: certificateService.pemURL)
//        certificateService.generateCertificate()
//    }
//    
//    override func tearDownWithError() throws {
//        if let channel = channel {
//            try channel.close().wait()
//        }
//        try eventLoopGroup.syncShutdownGracefully()
//        
//        try? FileManager.default.removeItem(at: certificateService.certificateURL)
//        try? FileManager.default.removeItem(at: certificateService.pemURL)
//        
//        certificateService = nil
//        configurationService = nil
//        loggingService = nil
//        filteringService = nil
//        networkingService = nil
//        eventLoopGroup = nil
//        
//        super.tearDown()
//    }
//    
//    func startServer() throws {
//        try networkingService.startServer()
//    }
//    
//    func testSSLProxyWithCurl() {
//        do {
//            try startServer()
//            sleep(2) // Wait a bit to ensure the server is fully started
//        } catch {
//            XCTFail("Failed to start server: \(error)")
//            return
//        }
//        
//        let curlCommand = """
//            curl -k https://localhost:8443 -v
//            """
//        
//        let task = Process()
//        task.launchPath = "/bin/bash"
//        task.arguments = ["-c", curlCommand]
//        
//        let outputPipe = Pipe()
//        let errorPipe = Pipe()
//        task.standardOutput = outputPipe
//        task.standardError = errorPipe
//        
//        task.launch()
//        task.waitUntilExit()
//        
//        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
//        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: outputData, encoding: .utf8) ?? ""
//        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
//        
//        XCTAssertEqual(task.terminationStatus, 0, "Curl command failed with exit code \(task.terminationStatus)")
//        XCTAssertTrue(output.contains("Expected content"), "Curl output did not contain expected content. Output: \(output)")
//        XCTAssertTrue(errorOutput.isEmpty, "Curl error: \(errorOutput)")
//    }
//    
//    func testSSLProxyWithCurlBlockingRequest() {
//        do {
//            try startServer()
//            sleep(2) // Wait a bit to ensure the server is fully started
//        } catch {
//            XCTFail("Failed to start server: \(error)")
//            return
//        }
//        
//        let curlCommand = """
//            curl -k https://localhost:8443/blocked -v
//            """
//        
//        let task = Process()
//        task.launchPath = "/bin/bash"
//        task.arguments = ["-c", curlCommand]
//        
//        let outputPipe = Pipe()
//        let errorPipe = Pipe()
//        task.standardOutput = outputPipe
//        task.standardError = errorPipe
//        
//        task.launch()
//        task.waitUntilExit()
//        
//        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
//        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
//        let output = String(data: outputData, encoding: .utf8) ?? ""
//        let errorOutput = String(data: errorData, encoding: .utf8) ?? ""
//        
//        XCTAssertEqual(task.terminationStatus, 0, "Curl command failed with exit code \(task.terminationStatus)")
//        XCTAssertTrue(output.contains("Forbidden"), "Curl error did not contain expected 'Forbidden' message. Error: \(errorOutput)")
//    }
//}
