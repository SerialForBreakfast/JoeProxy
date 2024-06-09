import Foundation
import Combine

class LogViewModel: ObservableObject {
    @Published var logs: [LogEntry] = []
    @Published var filteredLogs: [LogEntry] = []
    @Published var selectedLogEntry: LogEntry?
    @Published var filterText: String = ""

    private let loggingService: LoggingService
    private var cancellables = Set<AnyCancellable>()

    init(loggingService: LoggingService) {
        self.loggingService = loggingService
        setupLogsPublisher()
        setupFiltering()
    }

    private func setupLogsPublisher() {
        loggingService.logsPublisher
            .map { logs in
                logs.map { logString in
                    LogEntry(
                        timestamp: Date(), // replace with actual parsed timestamp
                        request: logString, // replace with actual parsed request
                        headers: "231", // replace with actual parsed headers
                        response: "fdsvs", // replace with actual parsed response
                        responseBody: "response body text", // replace with actual parsed response body
                        statusCode: 200 // replace with actual parsed status code
                    )
                }
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newLogs in
                print("Received logs update")
                self?.logs = newLogs
                self?.filterLogs()
            }
            .store(in: &cancellables)
    }

    private func setupFiltering() {
        $filterText
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .sink { [weak self] _ in
                self?.filterLogs()
            }
            .store(in: &cancellables)
    }

    func filterLogs() {
        print("Filtering logs with text: \(filterText)")
        if filterText.isEmpty {
            filteredLogs = logs
        } else {
            filteredLogs = logs.filter { log in
                log.request.contains(filterText) ||
                log.headers.contains(filterText) ||
                log.response.contains(filterText) ||
                log.responseBody.contains(filterText)
            }
        }
        print("Filtered logs: \(filteredLogs.count) logs")
    }

    func saveLogsToFile() {
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
