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
    @State private var filterText = ""

    var body: some View {
        VStack {
            HStack {
                FilteringLogView()
                InspectorView(logEntry: selectedLogEntry)
                    .frame(minWidth: 600, minHeight: 400)
            }
            HStack {
                CertificateConfigurationView(certificateService: certificateService)
                    .frame(minWidth: 600, minHeight: 400)
                SetupInstructionView(networkingViewModel: networkingViewModel)
                    .frame(minWidth: 600, minHeight: 400)
            }
        }
        .onAppear {
            logViewModel.loadLogs()
            networkingViewModel.refreshNetworkInfo()
            if let firstInterface = networkingViewModel.networkInfo.first {
                networkingViewModel.selectedInterface = firstInterface
            }
        }
    }
}
