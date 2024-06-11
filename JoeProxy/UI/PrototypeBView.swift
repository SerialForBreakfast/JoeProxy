//
//  PrototypeBView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import Foundation
import SwiftUI

struct PrototypeBView: View {
    @ObservedObject var logViewModel: LogViewModel
    @ObservedObject var certificateService: CertificateService
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel
    @State private var selectedLogEntry: LogEntry?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                LogView(viewModel: logViewModel, selectedLogEntry: $selectedLogEntry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .border(Color.gray)

                InspectorView(logEntry: selectedLogEntry ?? LogEntry.default)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .border(Color.gray)

                CertificateConfigurationView(certificateService: certificateService)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .border(Color.gray)

                SetupInstructionView(networkingViewModel: networkingViewModel)
                    .frame(maxWidth: .infinity, minHeight: 200)
                    .border(Color.gray)
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

extension LogEntry {
    static let `default` = LogEntry(
        timestamp: Date(),
        host: "N/A",
        path: "N/A",
        request: "N/A",
        headers: "N/A",
        response: "N/A",
        responseBody: "N/A",
        statusCode: 0
    )
}
