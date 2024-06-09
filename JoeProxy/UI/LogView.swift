import SwiftUI
import Combine

struct LogView: View {
    @ObservedObject var viewModel: LogViewModel
    @State private var searchText = ""
    @State private var isPaused = false
    @Binding var selectedLogEntry: LogEntry?

    var body: some View {
        VStack {
            HStack {
                TextField("Filter logs...", text: $viewModel.filterText)
                    .padding()
                Button(isPaused ? "Resume" : "Pause") {
                    isPaused.toggle()
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
            .onAppear {
                viewModel.loadLogs()
            }
        }
        .onAppear {
            print("LogView onAppear called")
            viewModel.loadLogs()
        }
        .onChange(of: viewModel.selectedLogEntry) { newSelection in
            print("Log selected: \(String(describing: newSelection))")
        }
    }
}

struct LogView_Previews: PreviewProvider {
    @State static var selectedLogEntry: LogEntry? = nil

    static var previews: some View {
        LogView(viewModel: LogViewModel(loggingService: MockLoggingService()), selectedLogEntry: $selectedLogEntry)
    }
}
