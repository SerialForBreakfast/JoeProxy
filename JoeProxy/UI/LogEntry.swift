//
//  LogEntry.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import Foundation

struct LogEntry: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let host: String
    let path: String
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

    static func ==(lhs: LogEntry, rhs: LogEntry) -> Bool {
        return lhs.id == rhs.id
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

struct MockLogs {
    static let logs: [LogEntry] = [
        LogEntry(timestamp: Date(), host: "example.com", path: "/index.html", request: "GET /index.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "200 OK", responseBody: "{ \"data\": \"example\" }", statusCode: 200),
        LogEntry(timestamp: Date().addingTimeInterval(-60), host: "api.example.com", path: "/api/data", request: "POST /api/data", headers: "Host: api.example.com\nContent-Type: application/json", response: "201 Created", responseBody: "{ \"data\": \"example\" }", statusCode: 201),
        LogEntry(timestamp: Date().addingTimeInterval(-120), host: "example.com", path: "/notfound.html", request: "GET /notfound.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "404 Not Found", responseBody: "{ \"data\": \"example\" }", statusCode: 404),
        LogEntry(timestamp: Date().addingTimeInterval(-180), host: "api.example.com", path: "/api/data/1", request: "DELETE /api/data/1", headers: "Host: api.example.com\nAuthorization: Bearer token", response: "204 No Content", responseBody: "", statusCode: 204),
        LogEntry(timestamp: Date().addingTimeInterval(-240), host: "api.example.com", path: "/api/data/1", request: "PUT /api/data/1", headers: "Host: api.example.com\nContent-Type: application/json", response: "200 OK", responseBody: "{ \"data\": \"example\" }", statusCode: 200)
    ]
}
