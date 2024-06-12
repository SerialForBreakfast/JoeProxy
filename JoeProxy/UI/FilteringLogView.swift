import SwiftUI
import Foundation
import Combine

class LogStateStore: ObservableObject {
    @Published var selectedLogEntry: LogEntry?
}

struct FilteringLogView: View {
    @State private var logs: [LogEntry] = MockLogs.data
    @State private var filteredLogs: [LogEntry] = MockLogs.data
    @State private var filterText = ""
    @EnvironmentObject var logStateStore: LogStateStore

    @State private var selectedRowIDs: Set<LogEntry.ID> = []

    var body: some View {
        VStack {
            TextField("Filter logs...", text: $filterText)
                .padding()
                .onChange(of: filterText) { newValue in
                    filterLogs(with: newValue)
                }

            Table(filteredLogs, selection: $selectedRowIDs) {
                TableColumn("Timestamp") { log in
                    Text(log.timestampString)
                }
                TableColumn("Host") { log in
                    Text(log.host)
                }
                TableColumn("Path") { log in
                    Text(log.path)
                }
                TableColumn("Request") { log in
                    Text(log.request)
                }
                TableColumn("Headers") { log in
                    Text(log.headers)
                }
                TableColumn("Response") { log in
                    Text(log.response)
                }
                TableColumn("Status Code") { log in
                    Text(log.statusCodeString)
                }
            }
            .onChange(of: selectedRowIDs) { newSelection in
                if let selectedID = newSelection.first, let selectedLog = filteredLogs.first(where: { $0.id == selectedID }) {
                    logStateStore.selectedLogEntry = selectedLog
                }
            }
        }
    }

    private func filterLogs(with filterText: String) {
        if filterText.isEmpty {
            filteredLogs = logs
        } else {
            filteredLogs = logs.filter { log in
                log.request.contains(filterText) ||
                log.headers.contains(filterText) ||
                log.response.contains(filterText)
            }
        }
    }
}
