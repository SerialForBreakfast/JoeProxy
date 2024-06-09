import SwiftUI

struct InspectorView: View {
    let logEntry: LogEntry

    var body: some View {
        VStack(alignment: .leading) {
            Text("Request: \(logEntry.request)")
                .font(.headline)
            Text("Headers: \(logEntry.headers)")
                .font(.subheadline)
            Text("Response: \(logEntry.response)")
                .font(.subheadline)
            Text("Status Code: \(logEntry.statusCode)")
                .font(.subheadline)
            Text("Timestamp: \(logEntry.timestampString)")
                .font(.subheadline)
            Text("Response Body: \(prettifyJSON(logEntry.responseBody))")
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
