//
//  NetworkInfoView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//
import SwiftUI

struct NetworkInfoView: View {
    @State private var networkDetails: [String: String] = [:]
    @State private var pingResult: String = ""

    var body: some View {
        VStack(alignment: .leading) {
            Text("Network Information")
                .font(.headline)
            List(networkDetails.keys.sorted(), id: \.self) { key in
                HStack {
                    Text(key)
                    Spacer()
                    Text(networkDetails[key] ?? "")
                }
            }
            Text("Ping an IP")
                .font(.headline)
            HStack {
                TextField("Enter IP", text: .constant(""))
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                Button("Ping") {
                    // Ping logic here
                }
            }
            Text("Ping Result: \(pingResult)")
                .font(.body)
            Spacer()
        }
        .padding()
        .onAppear {
            loadNetworkInformation()
        }
    }

    private func loadNetworkInformation() {
        // Logic to load network information
        // Example: networkDetails["IP Address"] = "192.168.1.1"
    }
}
