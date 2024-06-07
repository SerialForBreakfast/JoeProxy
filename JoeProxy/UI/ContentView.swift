//
//  ContentView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

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
                Text("Certificate exists, created on \(creationDate)")
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

            LogView(viewModel: viewModel)
            
            Button("Save Logs") {
                viewModel.saveLog() // Updated method call to saveLogs
            }
            .padding()
        }
        .onAppear {
            certificateService.checkCertificateExists() // Should work now as the method is not private anymore
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let mockLoggingService = MockLoggingService()
        ContentView(loggingService: mockLoggingService)
    }
}
