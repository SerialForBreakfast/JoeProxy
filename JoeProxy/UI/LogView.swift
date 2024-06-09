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
    @State private var debounceCancellable: AnyCancellable?

    private let filterSubject = PassthroughSubject<String, Never>()
    @State private var isUpdatingLogs = false

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
        .onAppear {
            print("LogView onAppear called.")
            debounceCancellable = filterSubject
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { newFilterText in
                    print("Filtering logs with: \(newFilterText)")
                }

            cancellable = viewModel.$logs
                .dropFirst()
                .sink { logs in
                    if !isPaused {
                        viewModel.updateLogs(with: logs)
                    }
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
