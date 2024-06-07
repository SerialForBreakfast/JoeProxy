//
//  LogginServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/6/24.
//

import XCTest
import Combine

@testable import JoeProxy

class LoggingServiceTests: XCTestCase {
    
    var loggingService: LoggingService!
    var configurationService: MockConfigurationService!
    
    override func setUpWithError() throws {
        configurationService = MockConfigurationService()
        loggingService = DefaultLoggingService(configurationService: configurationService)
    }

    override func tearDownWithError() throws {
        loggingService = nil
        configurationService = nil
    }

    func testLogMessageWithAppropriateLevel() throws {
        // Set log level to debug
        configurationService.logLevel = .debug
        
        // Log a message with debug level
        loggingService.log("Test Debug Message", level: .debug)
        
        // Assert the logged message
        XCTAssertTrue(loggingService.logs.contains("[DEBUG] Test Debug Message"))
    }

    func testDoNotLogMessageWithLowerLevel() throws {
        // Set log level to error
        configurationService.logLevel = .error
        
        // Attempt to log a message with debug level
        loggingService.log("Test Debug Message", level: .debug)
        
        // Assert the logged message is not present
        XCTAssertFalse(loggingService.logs.contains("[DEBUG] Test Debug Message"))
    }
}

// Mock ConfigurationService for testing purposes
class MockConfigurationService: ConfigurationService {
    var proxyPort: Int = 0
    var logLevel: LogLevel = .info
}

class MockLoggingService: LoggingService {
    private(set) var logs: [String] = []

    private let logsSubject = CurrentValueSubject<[String], Never>([])
    var logsPublisher: AnyPublisher<[String], Never> {
        logsSubject.eraseToAnyPublisher()
    }

    func logRequest(_ request: String, headers: [String: String], timestamp: Date) {
        let formattedHeaders = headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let logMessage = "[REQUEST] \(timestamp) \(request) Headers: \(formattedHeaders)"
        logs.append(logMessage)
        logsSubject.send(logs)
    }

    func logResponse(_ response: String, statusCode: Int, timestamp: Date) {
        let logMessage = "[RESPONSE] \(timestamp) \(response) Status: \(statusCode)"
        logs.append(logMessage)
        logsSubject.send(logs)
    }

    func log(_ message: String, level: LogLevel) {
        let logMessage = "[\(level.rawValue.uppercased())] \(message)"
        logs.append(logMessage)
        logsSubject.send(logs)
    }

    func saveLogsToFile() {
        // Mock implementation
    }
}
