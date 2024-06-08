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
        VStack(alignment: .leading) {
            Text("Request: \(logEntry.request)")
                .font(.headline)
            Text("Headers: \(logEntry.headers)")
                .font(.subheadline)
            Text("Status Code: \(logEntry.statusCode)")
                .font(.subheadline)
            Text("Response: \(prettifyJSON(logEntry.response))")
                .font(.body)
            Spacer()
        }
        .padding()
    }

    private func prettifyJSON(_ jsonString: String) -> String {
        guard let data = jsonString.data(using: .utf8) else { return jsonString }
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []),
              let prettyData = try? JSONSerialization.data(withJSONObject: jsonObject, options: .prettyPrinted) else {
            return jsonString
        }
        return String(data: prettyData, encoding: .utf8) ?? jsonString
    }
}
