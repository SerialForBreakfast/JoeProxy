//
//  LoggingService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//
import Foundation
import Combine

protocol LoggingService {
    func log(_ message: String, level: LogLevel)
    var logs: [String] { get }
    var logsPublisher: AnyPublisher<[String], Never> { get }
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
    
    func log(_ message: String, level: LogLevel) {
        guard level.rawValue >= configurationService.logLevel.rawValue else { return }
        let logMessage = "[\(level.rawValue.uppercased())] \(message)"
        print(logMessage)
        logs.append(logMessage)
        logsSubject.send(logs)
    }
}
