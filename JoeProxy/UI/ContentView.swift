import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LogViewModel
    @ObservedObject var certificateService: CertificateService
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel
    
    @State private var showingNetworkInfo = false
    @State private var showingInspector = false
    @State private var selectedLogEntry: LogEntry?
    @State private var filterText: String = ""
    
    var body: some View {
        VStack {
            HStack {
                if certificateService.certificateExists {
                    Text("Certificate exists, created on \(certificateService.certificateCreationDate ?? Date())")
                    Button("Open Certificate Directory") {
                        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: certificateService.certificateURL.deletingLastPathComponent().path)
                    }
                } else {
                    Text("No certificate found")
                }

                Button("Generate Certificate") {
                    do {
                        try certificateService.generateCertificate()
                    } catch {
                        print("Failed to generate certificate: \(error)")
                    }
                }
                .padding()

                Button(networkingViewModel.isServerRunning ? "Stop Server" : "Start Server") {
                    networkingViewModel.isServerRunning ? networkingViewModel.stopServer() : networkingViewModel.startServer()
                }
                .padding()
            }
            
            LogView(viewModel: viewModel, selectedLogEntry: $selectedLogEntry)
            Button("Save Logs") {
                viewModel.saveLogsToFile()
            }
            .padding()

            Button("Network Information") {
                showingNetworkInfo.toggle()
            }
            .padding()
            .sheet(isPresented: $showingNetworkInfo) {
                NetworkInfoView()
            }
        }
        .onAppear {
            print("ContentView onAppear called.")
            viewModel.loadLogs()
        }
        .onReceive(viewModel.logsPublisher) { logs in
            // Automatically select the first log entry if available
            if selectedLogEntry == nil, let firstLog = logs.first {
                selectedLogEntry = firstLog
            }
        }
        .onChange(of: selectedLogEntry) { newSelection in
            if let newLogEntry = newSelection {
                viewModel.selectedLogEntry = newLogEntry
            }
        }
    }
}
