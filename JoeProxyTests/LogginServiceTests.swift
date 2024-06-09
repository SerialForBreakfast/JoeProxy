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
    var loggingService: MockLoggingService!
    var configurationService: MockConfigurationService!
    
    override func setUpWithError() throws {
        configurationService = MockConfigurationService()
        loggingService = MockLoggingService()
    }

    override func tearDownWithError() throws {
        loggingService = nil
        configurationService = nil
    }
    
    func testLogRequest() throws {
        let headers = ["Content-Type": "application/json", "Accept": "*/*"]
        loggingService.logRequest("https://example.com/api", headers: headers, timestamp: Date())
        
        XCTAssertTrue(loggingService.logs.last?.contains("[REQUEST]") ?? false)
    }

    func testLogResponse() throws {
        loggingService.logResponse("https://example.com/api", statusCode: 200, timestamp: Date())
        
        XCTAssertTrue(loggingService.logs.last?.contains("[RESPONSE]") ?? false)
    }

    func testLog() throws {
        loggingService.log("This is a test log message.", level: .info)
        
        XCTAssertTrue(loggingService.logs.last?.contains("[INFO]") ?? false)
    }

    func testLogsPublisher() throws {
        let expectation = XCTestExpectation(description: "Logs Publisher")
        var cancellable: AnyCancellable?
        
        cancellable = loggingService.logsPublisher
            .dropFirst() // Ignore the initial empty value from CurrentValueSubject
            .sink { logs in
                XCTAssertFalse(logs.isEmpty, "Logs should not be empty")
                expectation.fulfill()
                cancellable?.cancel()
            }
        
        loggingService.log("This is another test log message.", level: .debug)
        
        wait(for: [expectation], timeout: 1.0)
    }
}

// Mock ConfigurationService for testing purposes
class MockConfigurationService: ConfigurationService {
    var logLevel: LogLevel = .info
    var proxyPort: Int = 8081
}

class MockLoggingService: LoggingService {
    private var loggedMessagesInternal: [String] = []
    var logs: [String] {
        return loggedMessagesInternal
    }
    
    private let logsSubject = CurrentValueSubject<[String], Never>([])
    var logsPublisher: AnyPublisher<[String], Never> {
        logsSubject.eraseToAnyPublisher()
    }
    
    func logRequest(_ request: String, headers: [String: String], timestamp: Date) {
        let formattedHeaders = headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let logMessage = "[REQUEST] \(timestamp) \(request) Headers: \(formattedHeaders)"
        log(logMessage, level: .info)
    }
    
    func logResponse(_ response: String, statusCode: Int, timestamp: Date) {
        let logMessage = "[RESPONSE] \(timestamp) \(response) Status: \(statusCode)"
        log(logMessage, level: .info)
    }
    
    func log(_ message: String, level: LogLevel) {
        let logMessage = "[\(level.rawValue.uppercased())] \(message)"
        loggedMessagesInternal.append(logMessage)
        logsSubject.send(loggedMessagesInternal)
    }
    
    func saveLogsToFile(logs: [LogEntry]) {
        // Mock implementation, do nothing or log to internal storage
    }

    var loggedMessages: [String] {
        return loggedMessagesInternal
    }
}
