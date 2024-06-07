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
                certificateService.generateCertificate()
            }
            .padding()

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
