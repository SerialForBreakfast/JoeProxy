//
//  LogViewModel.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//
import SwiftUI
import Combine

class LogViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var selectedLogEntry: LogEntry?

    private let loggingService: LoggingService

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        setupLogsPublisher()
    }

    func filteredLogs(_ filterText: String) -> [LogEntry] {
        print("filtering logs \(filterText)")
        if filterText.isEmpty {
            return logs
        } else {
            return logs.filter { log in
                log.request.contains(filterText) ||
                log.headers.contains(filterText) ||
                log.response.contains(filterText)
            }
        }
    }

    func filterLogs(with filterText: String) {
        logs = filteredLogs(filterText)
    }

    func setupLogsPublisher() {
        loggingService.logsPublisher
            .map { logs in
                logs.map { logString in
                    // Parse logString into LogEntry
                    // For example purposes, assuming logString is parsed into LogEntry components
                    LogEntry(
                        timestamp: Date(), // replace with actual parsed timestamp
                        request: logString, // replace with actual parsed request
                        headers: "231", // replace with actual parsed headers
                        response: "fdsvs", // replace with actual parsed response
                        statusCode: 200 // replace with actual parsed status code
                    )
                }
            }
            .assign(to: &$logs)
    }

    var logsPublisher: AnyPublisher<[LogEntry], Never> {
        loggingService.logsPublisher
            .map { logs in
                logs.map { logString in
                    // Parse logString into LogEntry
                    // For example purposes, assuming logString is parsed into LogEntry components
                    LogEntry(
                        timestamp: Date(), // replace with actual parsed timestamp
                        request: logString, // replace with actual parsed request
                        headers: "", // replace with actual parsed headers
                        response: "", // replace with actual parsed response
                        statusCode: 200 // replace with actual parsed status code
                    )
                }
            }
            .eraseToAnyPublisher()
    }
    
    func loadLogs() {
        print("Loading logs...")
        // Implement logic to load logs
            logs = [
                LogEntry(timestamp: Date(), request: "GET /index.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "200 OK", statusCode: 200),
                LogEntry(timestamp: Date().addingTimeInterval(-60), request: "POST /api/data", headers: "Host: example.com\nContent-Type: application/json", response: "201 Created", statusCode: 201),
                LogEntry(timestamp: Date().addingTimeInterval(-120), request: "GET /notfound.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "404 Not Found", statusCode: 404),
                LogEntry(timestamp: Date().addingTimeInterval(-180), request: "DELETE /api/data/1", headers: "Host: example.com\nAuthorization: Bearer token", response: "204 No Content", statusCode: 204),
                LogEntry(timestamp: Date().addingTimeInterval(-240), request: "PUT /api/data/1", headers: "Host: example.com\nContent-Type: application/json", response: "200 OK", statusCode: 200)
            ]
        print("Logs loaded.")
    }
    
    func saveLogsToFile() {
        loggingService.saveLogsToFile()
    }
}
