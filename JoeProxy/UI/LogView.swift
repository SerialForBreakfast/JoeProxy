import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var isPaused = false
    @Binding var selectedLogEntry: LogEntry?
    @State private var filterText: String = ""
    @State private var cancellables = Set<AnyCancellable>()

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
            HStack {
                LogTableView(logs: viewModel.filteredLogs) { selectedLog in
                    selectedLogEntry = selectedLog
                }
            }
        }
        .onAppear {
            filterSubject
                .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
                .removeDuplicates()
                .sink { newFilterText in
                    print("Filtering logs with: \(newFilterText)")
                    viewModel.filterLogs(with: newFilterText)
                }
                .store(in: &cancellables)

            viewModel.$logs
                .dropFirst()
                .receive(on: RunLoop.main)
                .sink { logs in
                    if !isPaused {
                        viewModel.updateLogs(with: logs)
                    }
                }
                .store(in: &cancellables)
        }
    }
}

struct LogView_Previews: PreviewProvider {
    @State static var selectedLogEntry: LogEntry? = nil

    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()), selectedLogEntry: $selectedLogEntry)
    }
}
