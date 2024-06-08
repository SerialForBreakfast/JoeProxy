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
    private let loggingService: LoggingService
    
    private var cancellables: Set<AnyCancellable> = []
    var logsPublisher: AnyPublisher<[LogEntry], Never> {
        $logs.eraseToAnyPublisher()
    }
    
    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        setupBindings()
    }
    
    private func setupBindings() {
        loggingService.logsPublisher
            .sink { [weak self] logs in
                self?.logs = logs.map { LogEntry(timestamp: Date(), request: $0, headers: "", response: "", statusCode: 200) } // Update as necessary
            }
            .store(in: &cancellables)
    }
    
    func loadLogs() {
            // Implement logic to load logs
            logs = [
                LogEntry(timestamp: Date(), request: "GET /index.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "200 OK", statusCode: 200),
                LogEntry(timestamp: Date().addingTimeInterval(-60), request: "POST /api/data", headers: "Host: example.com\nContent-Type: application/json", response: "201 Created", statusCode: 201),
                LogEntry(timestamp: Date().addingTimeInterval(-120), request: "GET /notfound.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "404 Not Found", statusCode: 404),
                LogEntry(timestamp: Date().addingTimeInterval(-180), request: "DELETE /api/data/1", headers: "Host: example.com\nAuthorization: Bearer token", response: "204 No Content", statusCode: 204),
                LogEntry(timestamp: Date().addingTimeInterval(-240), request: "PUT /api/data/1", headers: "Host: example.com\nContent-Type: application/json", response: "200 OK", statusCode: 200)
            ]
        }

    
    func saveLogsToFile() {
        loggingService.saveLogsToFile()
    }
    
}

import SwiftUI

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var isPaused = false
    @State private var queuedLogs: [LogEntry] = []
    
    var filteredLogs: [LogEntry] {
        if searchText.isEmpty {
            return viewModel.logs
        } else {
            return viewModel.logs.filter { $0.request.contains(searchText) || $0.response.contains(searchText) }
        }
    }
    
    var body: some View {
        VStack {
            HStack {
                TextField("Search logs...", text: $searchText)
                    .padding()
                
                Button(isPaused ? "Resume" : "Pause") {
                    isPaused.toggle()
                    if !isPaused {
                        viewModel.logs.append(contentsOf: queuedLogs)
                        queuedLogs.removeAll()
                    }
                }
                .padding()
            }
            
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
        .onReceive(viewModel.$logs) { logs in
            if isPaused {
                queuedLogs.append(contentsOf: logs)
            }
        }
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
