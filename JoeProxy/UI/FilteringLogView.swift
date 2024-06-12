//
//  FilteringLogView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import SwiftUI

struct FilteringLogView: View {
    @State private var filterText: String = ""
    @State private var filteredLogs: [LogEntry] = MockLogs.logs
    @State private var selectedLogEntry: LogEntry?

    var body: some View {
        VStack {
            Table(filteredLogs) {
                TableColumn("Timestamp", value: \.timestampString)
                TableColumn("Host", value: \.host)
                TableColumn("Path", value: \.path)
                TableColumn("Request", value: \.request)
                TableColumn("Headers", value: \.headers)
                TableColumn("Response", value: \.response)
                TableColumn("Status Code", value: \.statusCodeString)
            }
            .frame(minHeight: 300)
            .onChange(of: filterText) { newValue in
                applyFilter(newValue)
            }
            .onTapGesture {
                // Set the selected log entry when a row is clicked
                if let selectedIndex = filteredLogs.firstIndex(where: { $0.id == selectedLogEntry?.id }) {
                    selectedLogEntry = filteredLogs[selectedIndex]
                }
            }
            TextField("Filter logs...", text: $filterText)
                .padding()
        }
        .onAppear {
            filteredLogs = MockLogs.logs
        }
        .sheet(item: $selectedLogEntry) { log in
            InspectorView(logEntry: log)
        }
    }

    private func applyFilter(_ filter: String) {
        if filter.isEmpty {
            filteredLogs = MockLogs.logs
        } else {
            filteredLogs = MockLogs.logs.filter { log in
                log.host.contains(filter) ||
                log.path.contains(filter) ||
                log.request.contains(filter) ||
                log.headers.contains(filter) ||
                log.response.contains(filter) ||
                log.responseBody.contains(filter) ||
                log.statusCodeString.contains(filter)
            }
        }
    }
}

struct FilteringLogView_Previews: PreviewProvider {
    static var previews: some View {
        FilteringLogView()
    }
}
