import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var isPaused = false
    @State private var queuedLogs: [LogEntry] = []
    @State private var filterText: String = ""
    @State private var cancellable: AnyCancellable?
    @State private var debounceCancellable: AnyCancellable?
    @State private var selectedLogIndex: Int? = nil

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
                List(viewModel.filteredLogs(filterText).indices, id: \.self) { index in
                    HStack {
                        Text(viewModel.filteredLogs(filterText)[index].timestampString)
                        Spacer()
                        Text(viewModel.filteredLogs(filterText)[index].request)
                        Spacer()
                        Text(viewModel.filteredLogs(filterText)[index].headers)
                        Spacer()
                        Text(viewModel.filteredLogs(filterText)[index].response)
                        Spacer()
                        Text(viewModel.filteredLogs(filterText)[index].statusCodeString)
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedLogIndex = index
                        print("Row tapped, selected index: \(index)")
                    }
                }
                .listStyle(PlainListStyle())

                if let selectedIndex = selectedLogIndex, selectedIndex != -1 {
                    InspectorView(logEntry: viewModel.filteredLogs(filterText)[selectedIndex])
                        .frame(width: 300)
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
    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()))
    }
}
