//
//  PrototypeBView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import SwiftUI

struct PrototypeBView: View {
    @State private var selectedLogEntry: LogEntry?
    @ObservedObject var certificateService: CertificateService
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel

    var body: some View {
        VStack {
            HStack {
                FilteringLogView(selectedLogEntry: $selectedLogEntry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                InspectorView(logEntry: selectedLogEntry)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            HStack {
                CertificateConfigurationView(certificateService: certificateService)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                SetupInstructionView(networkingViewModel: networkingViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .onAppear {
            networkingViewModel.refreshNetworkInfo()
            if let firstInterface = networkingViewModel.networkInfo.first {
                networkingViewModel.selectedInterface = firstInterface
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
