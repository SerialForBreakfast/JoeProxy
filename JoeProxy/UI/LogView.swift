//
//  LogView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import SwiftUI
import Combine

class LogViewModel: ObservableObject {
    @Published var logs: [String] = []
    private var loggingService: LoggingService
    private var cancellables = Set<AnyCancellable>()
    
    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        loggingService.logsPublisher
            .sink { [weak self] newLogs in
                self?.logs = newLogs
            }
            .store(in: &cancellables)
    }
    
    func saveLogs() {
        loggingService.saveLogsToFile()
    }
}

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    
    var body: some View {
        List(viewModel.logs, id: \.self) { log in
            Text(log)
        }
    }
}

struct LogView_Previews: PreviewProvider {
    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()))
    }
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
