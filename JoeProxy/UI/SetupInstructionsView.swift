import SwiftUI

struct SetupInstructionView: View {
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel

    var body: some View {
        VStack(alignment: .leading) {
            Text("Setup Instructions")
                .font(.headline)
                .padding()

            Picker("Network Interface", selection: $networkingViewModel.selectedInterface) {
                ForEach(networkingViewModel.networkInfo, id: \.self) { interface in
                    Text(interface.interface).tag(interface as NetworkInterface?)
                }
            }
            .padding()
            .onAppear {
                if let firstInterface = networkingViewModel.networkInfo.first {
                    networkingViewModel.selectedInterface = firstInterface
                }
            }

            HStack {
                Text("IP Address: \(networkingViewModel.ipAddress ?? "N/A")")
                Text("Port: \(networkingViewModel.port)")
            }
            .padding()

            Button(networkingViewModel.isServerRunning ? "Stop Server" : "Start Server") {
                networkingViewModel.isServerRunning ? networkingViewModel.stopServer() : networkingViewModel.startServer()
            }
            .padding()
            .background(networkingViewModel.isServerRunning ? Color.green : Color.red)
            .foregroundColor(.white)
            .cornerRadius(5)

            Text("Instructions to connect:")
                .font(.subheadline)
                .padding()

            Text("1. Ensure the application is running.")
            Text("2. Select the network interface from the dropdown above.")
            Text("3. The IP address and port will be displayed.")
            Text("4. Use the displayed IP address and port to connect.")
        }
        .padding()
    }
}
