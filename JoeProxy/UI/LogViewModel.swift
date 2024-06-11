import Foundation
import Combine

class LogViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var filteredLogs: [LogEntry] = []
    @Published var selectedLogEntry: LogEntry?

    private let loggingService: LoggingService
    private var cancellables: Set<AnyCancellable> = []

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        setupLogsPublisher()
    }

    func filterLogs(with filterText: String) {
        DispatchQueue.main.async {
            if filterText.isEmpty {
                self.filteredLogs = self.logs
            } else {
                self.filteredLogs = self.logs.filter { log in
                    log.request.contains(filterText) ||
                    log.headers.contains(filterText) ||
                    log.response.contains(filterText)
                }
            }
        }
    }

    private func setupLogsPublisher() {
        loggingService.logsPublisher
            .map { logs in
                logs.map { logString in
                    LogEntry(
                        timestamp: Date(), // replace with actual parsed timestamp
                        host: logString, // replace with actual parsed request
                        path: "example headers", // replace with actual parsed headers
                        request: "example response", // replace with actual parsed response
                        headers: "example response body", // replace with actual parsed response body
                        response: "200", // replace with actual parsed status code
                        responseBody: "",
                        statusCode: 403
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLogs in
                self?.updateLogs(with: newLogs)
            }
            .store(in: &cancellables)
    }

    func loadLogs() {
        print("Loading logs...")
        DispatchQueue.main.async {
            self.logs = [
                LogEntry(timestamp: Date(), host: "example.com", path: "/index.html", request: "GET /index.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "200 OK", responseBody: "{ \"data\": \"example\" }", statusCode: 200),
                LogEntry(timestamp: Date().addingTimeInterval(-60), host: "api.example.com", path: "/api/data", request: "POST /api/data", headers: "Host: api.example.com\nContent-Type: application/json", response: "201 Created", responseBody: "{ \"data\": \"example\" }", statusCode: 201),
                LogEntry(timestamp: Date().addingTimeInterval(-120), host: "example.com", path: "/notfound.html", request: "GET /notfound.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "404 Not Found", responseBody: "{ \"data\": \"example\" }", statusCode: 404),
                LogEntry(timestamp: Date().addingTimeInterval(-180), host: "api.example.com", path: "/api/data/1", request: "DELETE /api/data/1", headers: "Host: api.example.com\nAuthorization: Bearer token", response: "204 No Content", responseBody: "", statusCode: 204),
                LogEntry(timestamp: Date().addingTimeInterval(-240), host: "api.example.com", path: "/api/data/1", request: "PUT /api/data/1", headers: "Host: api.example.com\nContent-Type: application/json", response: "200 OK", responseBody: "{ \"data\": \"example\" }", statusCode: 200)
            ]
            self.filteredLogs = self.logs
            print("Logs loaded.")
        }
    }

    func saveLogsToFile() {
        loggingService.saveLogsToFile(logs: logs)
    }

    func updateLogs(with newLogs: [LogEntry]) {
        DispatchQueue.main.async {
            if self.logs != newLogs {
                self.logs = newLogs
                self.filteredLogs = newLogs
                print("Updating logs")
            }
        }
    }
    // Ensure updateFilteredLogs is a method
    func updateFilteredLogs(with filterText: String) {
        if filterText.isEmpty {
            self.filteredLogs = self.logs
        } else {
            self.filteredLogs = self.logs.filter { log in
                log.request.contains(filterText) ||
                log.headers.contains(filterText) ||
                log.response.contains(filterText)
            }
        }
    }
}
