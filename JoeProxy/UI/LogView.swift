import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
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
                Button("Resume") {
                    // Resume logic here
                }
                .padding()
            }

            Table(viewModel.filteredLogs) {
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
