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
    func saveLogsToFile(logs: [LogEntry])
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
    
    func saveLogsToFile(logs: [LogEntry]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd 'at' hh.mm.ss a"
        let timestamp = dateFormatter.string(from: Date())
        
        let fileName = "\(timestamp) Logs.csv"
        let path = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        var csvText = "Timestamp,Request,Headers,Response,ResponseBody,StatusCode\n"
        
        for log in logs {
            let newLine = "\(log.timestampString),\(log.request),\(log.headers),\(log.response),\(log.responseBody),\(log.statusCodeString)\n"
            csvText.append(contentsOf: newLine)
        }
        
        do {
            try csvText.write(to: path, atomically: true, encoding: .utf8)
            print("Logs saved to file: \(path)")
        } catch {
            print("Failed to save logs to file: \(error)")
        }
    }
}
