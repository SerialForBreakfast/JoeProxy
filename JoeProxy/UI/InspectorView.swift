//
//  InspectorView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import Foundation
import SwiftUI

struct InspectorView: View {
    @Binding var selectedLog: LogEntry?

    var body: some View {
        VStack {
            if let log = selectedLog {
                Text("Timestamp: \(log.timestamp)")
                Text("Request: \(log.request)")
                Text("Headers: \(log.headers)")
                Text("Response: \(log.response)")
                Text("Status Code: \(log.statusCode)")
            } else {
                Text("Select a log to view details")
            }
        }
        .padding()
    }
}
