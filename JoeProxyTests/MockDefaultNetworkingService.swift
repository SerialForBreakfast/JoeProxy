//
//  MockDefaultNetworkingService.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/7/24.
//

import XCTest
import NIO
import NIOHTTP1
@testable import JoeProxy

// Mock Networking Service to avoid actual network operations
class MockDefaultNetworkingService: NetworkingService {
    func stopServer(completion: @escaping (Result<Void, any Error>) -> Void) {
        completion(.failure(NSError()))
    }
    
    func startServer(completion: @escaping (Result<Void, any Error>) -> Void) throws {
        completion(.failure(NSError()))
    }
    
    private let configurationService: ConfigurationService
    private let filteringService: FilteringService
    private let loggingService: LoggingService
    private let certificateService: CertificateService
    private var isServerRunning = false

    init(configurationService: ConfigurationService, filteringService: FilteringService, loggingService: LoggingService, certificateService: CertificateService) {
        self.configurationService = configurationService
        self.filteringService = filteringService
        self.loggingService = loggingService
        self.certificateService = certificateService
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

// Mock ConfigurationService for testing purposes
class MockDefaultNetworkingConfigurationService: ConfigurationService {
    var proxyPort: Int = 8081 // Use a non-restricted port
    var logLevel: LogLevel = .info
}
