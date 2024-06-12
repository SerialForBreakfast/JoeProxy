import SwiftUI

struct FilteringLogView: View {
    @State private var logs: [LogEntry] = MockLogs.data
    @State private var filteredLogs: [LogEntry] = MockLogs.data
    @State private var filterText = ""
    @Binding var selectedLogEntry: LogEntry?

    var body: some View {
        VStack {
            TextField("Filter logs...", text: $filterText)
                .padding()
                .onChange(of: filterText) { newValue in
                    filterLogs(with: newValue)
                }

            Table(filteredLogs) {
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
            .onTapGesture {
                selectedLogEntry = filteredLogs[0]  // Placeholder, update logic to handle row selection
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
