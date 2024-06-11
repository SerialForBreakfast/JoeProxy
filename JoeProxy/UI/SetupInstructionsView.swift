import SwiftUI

struct SetupInstructionView: View {
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel

    var body: some View {
        VStack {
            HStack {
                Text("Server Status:")
                Circle()
                    .fill(networkingViewModel.isServerRunning ? Color.green : Color.red)
                    .frame(width: 20, height: 20)
                Button(networkingViewModel.isServerRunning ? "Stop Server" : "Start Server") {
                    networkingViewModel.isServerRunning ? networkingViewModel.stopServer() : networkingViewModel.startServer()
                }
                .padding()
            }
            .padding()

            Text("Setup Instructions")
                .font(.title)
                .padding()

            Text("Current IP: \(networkingViewModel.ipAddress ?? "N/A")")
            Text("Current Port: \(networkingViewModel.port)")

            Picker("Network Interface", selection: $networkingViewModel.selectedInterface) {
                            ForEach(networkingViewModel.networkInfo) { interface in
                                Text(interface.interface)
                            }
                        }
            .pickerStyle(MenuPickerStyle())
            .onAppear {
                            networkingViewModel.refreshNetworkInfo()
                            networkingViewModel.selectedInterface = networkingViewModel.networkInfo.first
                        }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
        .background(ScrollView {
            VStack {
                // Content goes here
            }
        })
    }
}
