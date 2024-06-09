import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var isPaused = false
    @State private var queuedLogs: [LogEntry] = []
    @Binding var selectedLogEntry: LogEntry?
    @State private var filterText: String = ""
    @State private var cancellable: AnyCancellable?

    private let filterSubject = PassthroughSubject<String, Never>()

    var body: some View {
        VStack {
            HStack {
                TextField("Filter logs...", text: $filterText)
                    .padding()
                    .onChange(of: filterText) { newValue in
                        filterSubject.send(newValue)
                    }
                Button(isPaused ? "Resume" : "Pause") {
                    isPaused.toggle()
                }
                .padding()
            }

            Table(viewModel.filteredLogs(filterText)) {
                TableColumn("Timestamp") { log in
                    Text(log.timestampString)
                }
                TableColumn("Request", value: \.request)
                TableColumn("Headers", value: \.headers)
                TableColumn("Response", value: \.response)
                TableColumn("Status Code") { log in
                    Text(log.statusCodeString)
                }
            }
        }
        .onReceive(viewModel.logsPublisher) { logs in
            if !isPaused {
                viewModel.logs = logs
            }
        }
        .onAppear {
            cancellable = filterSubject
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { newFilterText in
                    viewModel.filterLogs(with: newFilterText)
                }
        }
    }
}

struct LogView_Previews: PreviewProvider {
    @State static var selectedLogEntry: LogEntry? = nil

    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()), selectedLogEntry: $selectedLogEntry)
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
