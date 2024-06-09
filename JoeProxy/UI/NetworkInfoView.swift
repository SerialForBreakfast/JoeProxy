import SwiftUI

struct NetworkInfoView: View {
    @State private var networkDetails: [String: String] = [:]
    @State private var pingResult: String = ""

    var body: some View {
        VStack {
            List(networkDetails.sorted(by: <), id: \.key) { key, value in
                HStack {
                    Text(key)
                    Spacer()
                    Text(value)
                }
            }
            .onAppear {
                fetchNetworkDetails()
            }

            HStack {
                TextField("Enter IP to ping", text: $pingResult)
                Button("Ping") {
                    pingIPAddress(pingResult)
                }
            }
            .padding()

            Text("Ping Result: \(pingResult)")
        }
        .padding()
    }

    private func fetchNetworkDetails() {
        // Fetch and update network details
        networkDetails = [
            "Local IP": "192.168.1.2",
            "External IP": "203.0.113.1",
            "Router": "192.168.1.1",
            "DNS": "8.8.8.8"
        ]
    }

    private func pingIPAddress(_ ipAddress: String) {
        // Implement ping logic and update pingResult
        pingResult = "Pinging \(ipAddress)..."
    }
}
