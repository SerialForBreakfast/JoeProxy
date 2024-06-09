import SwiftUI

struct ContentView: View {
    @ObservedObject var viewModel: LogViewModel
    @ObservedObject var certificateService: CertificateService
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel
    
    @State private var showingNetworkInfo = false
    @State private var selectedLogEntry: LogEntry?

    var body: some View {
        HStack {
            VStack {
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
            
            
            if let selectedLog = selectedLogEntry {
                InspectorView(logEntry: selectedLog)
                    .frame(width: 300) // Adjust width as necessary
            }
        }
        .onAppear {
            viewModel.loadLogs()
        }
    }
}
