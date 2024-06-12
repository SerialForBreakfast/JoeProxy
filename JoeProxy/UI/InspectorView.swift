import SwiftUI

struct InspectorView: View {
    var logEntry: LogEntry?

    var body: some View {
        VStack(alignment: .leading) {
            if let log = logEntry {
                Text("Request: \(log.request)")
                    .font(.headline)
                Text("Headers: \(log.headers)")
                    .font(.subheadline)
                Text("Response: \(log.response)")
                    .font(.subheadline)
                Text("Status Code: \(log.statusCode)")
                    .font(.subheadline)
                Text("Timestamp: \(log.timestampString)")
                    .font(.subheadline)
                Text("Response Body: \(prettifyJSON(log.responseBody))")
                    .font(.body)
            } else {
                Text("No log selected")
                    .font(.headline)
            }
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

struct InspectorView_Previews: PreviewProvider {
    static var previews: some View {
        InspectorView(logEntry: nil)
    }
}
