//
//  NetworkServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/6/24.
//

import XCTest
import NIO
import NIOSSL
@testable import JoeProxy


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

        try? networkingService.stopServer(completion: { [weak self] result in
//            self?.isServerRunning = false
        })// Use try? to safely attempt stopping the server
        networkingService = nil
        configurationService = nil
    }

    func testStartAndStopServer() throws {
        XCTAssertNoThrow(try networkingService.startServer(completion: { [weak self] result in
            
        }))
        XCTAssertNoThrow(try networkingService.stopServer(completion: { [weak self] result in
            
        }))
    }
}
