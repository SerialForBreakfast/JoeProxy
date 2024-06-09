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

    private func setupLogsPublisher() {
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
                        responseBody: "", // replace with actual parsed response body
                        statusCode: 200 // replace with actual parsed status code
                    )
                }
            }
            .assign(to: &$logs)
    }

    func loadLogs() {
        print("Loading logs...")
        // Implement logic to load logs
        logs = [
            LogEntry(timestamp: Date(), request: "GET /index.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "200 OK", responseBody: "{\"key\": \"value\"}", statusCode: 200),
            LogEntry(timestamp: Date().addingTimeInterval(-60), request: "POST /api/data", headers: "Host: example.com\nContent-Type: application/json", response: "201 Created", responseBody: "{\"data\": \"sample\"}", statusCode: 201),
            LogEntry(timestamp: Date().addingTimeInterval(-120), request: "GET /notfound.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "404 Not Found", responseBody: "Not Found", statusCode: 404),
            LogEntry(timestamp: Date().addingTimeInterval(-180), request: "DELETE /api/data/1", headers: "Host: example.com\nAuthorization: Bearer token", response: "204 No Content", responseBody: "", statusCode: 204),
            LogEntry(timestamp: Date().addingTimeInterval(-240), request: "PUT /api/data/1", headers: "Host: example.com\nContent-Type: application/json", response: "200 OK", responseBody: "{\"id\": 1, \"status\": \"updated\"}", statusCode: 200)
        ]
        print("Logs loaded.")
    }

    func saveLogsToFile() {
        loggingService.saveLogsToFile()
    }

    func updateLogs(with newLogs: [LogEntry]) {
        print("Updating logs")
        logs = newLogs
    }
}
