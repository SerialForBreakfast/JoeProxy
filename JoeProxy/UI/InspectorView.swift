import SwiftUI

struct InspectorView: View {
    let logEntry: LogEntry?

    var body: some View {
        VStack(alignment: .leading) {
            Text("Request: \(logEntry?.request ?? "N/A")")
                .font(.headline)
            Text("Headers: \(logEntry?.headers ?? "N/A")")
                .font(.subheadline)
            Text("Response: \(logEntry?.response ?? "N/A")")
                .font(.subheadline)
            Text("Status Code: \(logEntry?.statusCodeString ?? "N/A")")
                .font(.subheadline)
            Text("Timestamp: \(logEntry?.timestampString ?? "N/A")")
                .font(.subheadline)
            Text("Response Body: \(prettifyJSON(logEntry?.responseBody ?? "N/A"))")
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
