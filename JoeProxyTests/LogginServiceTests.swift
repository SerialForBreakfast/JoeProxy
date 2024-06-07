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
        
        cancellable = loggingService.logsPublisher.sink { logs in
            XCTAssertFalse(logs.isEmpty)
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
    private let logsSubject = CurrentValueSubject<[String], Never>([
        "[REQUEST] 2024-06-06 12:00:00 https://example.com/api Headers: Content-Type: application/json, Accept: */*",
        "[RESPONSE] 2024-06-06 12:00:01 https://example.com/api Status: 200",
        "[REQUEST] 2024-06-06 12:01:00 https://example.com/api Headers: Content-Type: application/json, Accept: */*",
        "[RESPONSE] 2024-06-06 12:01:01 https://example.com/api Status: 404"
    ])
    
    var logsPublisher: AnyPublisher<[String], Never> {
        logsSubject.eraseToAnyPublisher()
    }
    
    var logs: [String] {
        logsSubject.value
    }
    
    func logRequest(_ request: String, headers: [String: String], timestamp: Date) {
        let formattedHeaders = headers.map { "\($0.key): \($0.value)" }.joined(separator: ", ")
        let logMessage = "[REQUEST] \(timestamp) \(request) Headers: \(formattedHeaders)"
        logsSubject.value.append(logMessage)
        logsSubject.send(logsSubject.value)
    }
    
    func logResponse(_ response: String, statusCode: Int, timestamp: Date) {
        let logMessage = "[RESPONSE] \(timestamp) \(response) Status: \(statusCode)"
        logsSubject.value.append(logMessage)
        logsSubject.send(logsSubject.value)
    }
    
    func log(_ message: String, level: LogLevel) {
        let logMessage = "[\(level.rawValue.uppercased())] \(message)"
        logsSubject.value.append(logMessage)
        logsSubject.send(logsSubject.value)
    }
    
    func saveLogsToFile() {
        // Mock implementation
    }
}
