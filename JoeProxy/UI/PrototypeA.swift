//
//  PrototypeA.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import SwiftUI

struct PrototypeAView: View {
    @ObservedObject var viewModel: LogViewModel
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel

    @State private var filterText: String = ""
    @State private var isPaused: Bool = false

    var body: some View {
        VStack {
            HStack {
                TextField("Filter logs...", text: $filterText)
                    .padding()
                    .onChange(of: filterText) { newValue in
                        viewModel.updateFilteredLogs(with: newValue)
                    }
                Button(isPaused ? "Resume" : "Pause") {
                    isPaused.toggle()
                }
                .padding()
                Button("Save Logs") {
                    viewModel.saveLogsToFile()
                }
                .padding()
            }
            LogTableView(logs: viewModel.filteredLogs)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .onAppear {
            viewModel.loadLogs()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

