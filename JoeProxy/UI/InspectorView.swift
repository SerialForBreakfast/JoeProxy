//
//  InspectorView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import Foundation
import SwiftUI

struct InspectorView: View {
    let logEntry: LogEntry
    
    var body: some View {
        VStack {
            Text("Inspector")
                .font(.largeTitle)
                .padding()
            
            Text("Timestamp: \(logEntry.timestamp)")
            Text("Request: \(logEntry.request)")
            Text("Headers: \(logEntry.headers)")
            Text("Response: \(logEntry.response)")
            Text("Status Code: \(logEntry.statusCode)")
        }
        .padding()
    }
}
