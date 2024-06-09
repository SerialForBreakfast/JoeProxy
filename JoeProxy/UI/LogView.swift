import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var isPaused = false
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
        .onAppear {
            print("LogView onAppear called.")
            viewModel.loadLogs()

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
    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()))
    }
}
