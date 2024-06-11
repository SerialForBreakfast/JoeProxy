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
        GeometryReader { geometry in
            VStack {
                HStack(spacing: 0) {
                    LogView(viewModel: logViewModel, selectedLogEntry: $selectedLogEntry)
                        .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                        .border(Color.gray)

                    InspectorView(logEntry: selectedLogEntry ?? LogEntry.default)
                        .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                        .border(Color.gray)
                }

                HStack(spacing: 0) {
                    CertificateConfigurationView(certificateService: certificateService)
                        .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                        .border(Color.gray)

                    SetupInstructionView(networkingViewModel: networkingViewModel)
                        .frame(width: geometry.size.width / 2, height: geometry.size.height / 2)
                        .border(Color.gray)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
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
