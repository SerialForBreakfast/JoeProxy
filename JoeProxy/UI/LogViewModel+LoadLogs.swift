//
//  LogViewModel+LoadLogs.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import Foundation

extension LogViewModel {
    func loadLogs() {
        print("Loading logs...")
        // Implement logic to load logs
        logs = [
            LogEntry(timestamp: Date(), request: "GET /index.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "200 OK", responseBody: "{ \"message\": \"success\" }", statusCode: 200),
            LogEntry(timestamp: Date().addingTimeInterval(-60), request: "POST /api/data", headers: "Host: example.com\nContent-Type: application/json", response: "201 Created", responseBody: "{ \"id\": 1 }", statusCode: 201),
            LogEntry(timestamp: Date().addingTimeInterval(-120), request: "GET /notfound.html", headers: "Host: example.com\nUser-Agent: TestAgent", response: "404 Not Found", responseBody: "{ \"error\": \"not found\" }", statusCode: 404),
            LogEntry(timestamp: Date().addingTimeInterval(-180), request: "DELETE /api/data/1", headers: "Host: example.com\nAuthorization: Bearer token", response: "204 No Content", responseBody: "", statusCode: 204),
            LogEntry(timestamp: Date().addingTimeInterval(-240), request: "PUT /api/data/1", headers: "Host: example.com\nContent-Type: application/json", response: "200 OK", responseBody: "{ \"message\": \"updated\" }", statusCode: 200)
        ]
        print("Logs loaded.")
    }
}
