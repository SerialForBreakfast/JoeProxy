//
//  LoggingService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//
import Foundation
import Combine

enum LogLevel: String {
    case debug, info, warning, error
}

protocol LoggingService {
    func logRequest(_ request: String, headers: [String: String], timestamp: Date)
    func logResponse(_ response: String, statusCode: Int, timestamp: Date)
    func log(_ message: String, level: LogLevel)
    var logs: [String] { get }
    var logsPublisher: AnyPublisher<[String], Never> { get }
    func saveLogsToFile()
}

class DefaultLoggingService: LoggingService {
    private let configurationService: ConfigurationService
    private(set) var logs: [String] = []
    
    private let logsSubject = CurrentValueSubject<[String], Never>([])
    var logsPublisher: AnyPublisher<[String], Never> {
        logsSubject.eraseToAnyPublisher()
    }
    
    init(configurationService: ConfigurationService) {
        self.configurationService = configurationService
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
        guard level.rawValue >= configurationService.logLevel.rawValue else { return }
        let logMessage = "[\(level.rawValue.uppercased())] \(message)"
        print(logMessage)
        logs.append(logMessage)
        logsSubject.send(logs)
    }
    
    func saveLogsToFile() {
        let fileManager = FileManager.default
        let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
        guard let documentDirectory = urls.first else { return }
        let logFileURL = documentDirectory.appendingPathComponent("network_logs.txt")
        
        do {
            let logData = logs.joined(separator: "\n").data(using: .utf8)
            fileManager.createFile(atPath: logFileURL.path, contents: logData, attributes: nil)
            print("Logs saved to file: \(logFileURL.path)")
        } catch {
            print("Failed to save logs to file: \(error)")
        }
    }
}
