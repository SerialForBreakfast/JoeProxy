//
//  NetworkServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/6/24.
//

import XCTest
@testable import JoeProxy

protocol NetworkingService {
    func startServer() throws
    func stopServer() throws
}

class MockNetworkingService: NetworkingService {
    private let configurationService: ConfigurationService
    private var isServerRunning = false
    
    init(configurationService: ConfigurationService) {
        self.configurationService = configurationService
    }
    
    func startServer() throws {
        guard !isServerRunning else { throw NSError(domain: "Server already running", code: 1, userInfo: nil) }
        isServerRunning = true
        print("Mock server started on port \(configurationService.proxyPort)")
    }
    
    func stopServer() throws {
        guard isServerRunning else { throw NSError(domain: "Server not running", code: 1, userInfo: nil) }
        isServerRunning = false
        print("Mock server stopped.")
    }
}

class MockNetworkingConfigurationService: ConfigurationService {
    var proxyPort: Int = 8080
    var logLevel: LogLevel = .info
}

class NetworkingServiceTests: XCTestCase {
    
    var networkingService: NetworkingService!
    var configurationService: MockNetworkingConfigurationService!
    
    override func setUpWithError() throws {
        configurationService = MockNetworkingConfigurationService()
        networkingService = MockNetworkingService(configurationService: configurationService)
    }

    override func tearDownWithError() throws {
        try? networkingService.stopServer() // Use try? to safely attempt stopping the server
        networkingService = nil
        configurationService = nil
    }

    func testStartAndStopServer() throws {
        XCTAssertNoThrow(try networkingService.startServer())
        XCTAssertNoThrow(try networkingService.stopServer())
    }
}
