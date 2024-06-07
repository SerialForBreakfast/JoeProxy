import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: LogViewModel
    @StateObject private var certificateService = CertificateService()
    
    init(loggingService: LoggingService) {
        _viewModel = StateObject(wrappedValue: LogViewModel(loggingService: loggingService))
    }
    
    var body: some View {
        VStack {
            if certificateService.certificateExists, let creationDate = certificateService.certificateCreationDate {
                HStack {
                    Text("Certificate exists, created on \(creationDate)")
//                    Button("Open Directory") {
//                        NSWorkspace.shared.open(certificateService.certificateURL.deletingLastPathComponent())
//                    }
                }
            } else {
                Text("No certificate found")
            }
            
            HStack {
                Button("Generate Certificate") {
                    do {
                        try certificateService.generateCertificate()
                    } catch {
                        print("Failed to generate certificate: \(error)")
                    }
                }
                .padding()
                
                if certificateService.certificateExists {
                    Button("Open Directory") {
                        NSWorkspace.shared.open(certificateService.certificateURL.deletingLastPathComponent())
                    }
                }
            }
            
            LogView(viewModel: viewModel)
            Button("Save Logs") {
                viewModel.saveLog()
            }
            .padding()
        }
        .onAppear {
            certificateService.checkCertificateExists()
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLoggingService = MockLoggingService()
        ContentView(loggingService: mockLoggingService)
    }
}
