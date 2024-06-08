//
//  LogView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import SwiftUI
import Combine
import Foundation

class LogViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    private var loggingService: LoggingService
    private var cancellables = Set<AnyCancellable>()
    
    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        loggingService.logsPublisher
            .map { logMessages in
                // Convert log messages to LogEntry instances
                logMessages.map { logMessage in
                    LogEntry(timestamp: Date(), request: logMessage, headers: "", response: "", statusCode: 200) // Adjust fields as needed
                }
            }
            .assign(to: &$logs)
    }
    
    func saveLogs() {
        loggingService.saveLogsToFile()
    }
}

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""

    var filteredLogs: [LogEntry] {
        if searchText.isEmpty {
            return viewModel.logs
        } else {
            return viewModel.logs.filter { $0.request.contains(searchText) || $0.response.contains(searchText) }
        }
    }

    var body: some View {
        VStack {
            TextField("Search logs...", text: $searchText)
                .padding()
            Table(filteredLogs) {
                TableColumn("Timestamp") { log in
                    Text(log.timestamp, style: .date)
                }
                TableColumn("Request", value: \.request)
                TableColumn("Headers", value: \.headers)
                TableColumn("Response", value: \.response)
                TableColumn("Status Code") { log in
                    Text("\(log.statusCode)")
                }
            }
            .tableStyle(InsetTableStyle()) // Optional, to add table style
        }
        .padding()
    }
}

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let request: String
    let headers: String
    let response: String
    let statusCode: Int
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
