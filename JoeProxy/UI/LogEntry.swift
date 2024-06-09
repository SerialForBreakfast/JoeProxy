//
//  LogEntry.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import Foundation

struct LogEntry: Identifiable {
    let id = UUID()
    let timestamp: Date
    let request: String
    let headers: String
    let response: String
    let responseBody: String
    let statusCode: Int

    var timestampString: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: timestamp)
    }

    var statusCodeString: String {
        return String(statusCode)
    }
}
