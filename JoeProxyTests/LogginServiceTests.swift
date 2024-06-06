//
//  LogginServiceTests.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/6/24.
//

import XCTest
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
