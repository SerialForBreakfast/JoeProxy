import SwiftUI

struct SetupInstructionsView: View {
    @State private var selectedPlatform: Platform = .iOS
    @State private var selectedInterface: String = ""
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel
    private let certificateService: CertificateService
    
    private let networkInfo = NetworkInformation.shared.getNetworkInformation()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("Share Certificate") {
                    shareCertificate()
                }
                .padding()
                
                Button("Refresh Network Information") {
                    refreshNetworkInfo()
                }
                .padding()
            }
            Text("Setup Instructions")
                .font(.title)
                .padding(.bottom, 20)
            
            Picker("Select Platform", selection: $selectedPlatform) {
                ForEach(Platform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)
            
            Picker("Select Network Interface", selection: $selectedInterface) {
                ForEach(networkInfo, id: \.interface) { info in
                    Text("\(info.interface): \(info.ipAddress)").tag(info.interface)
                }
            }
            .padding(.bottom, 20)
            
            if let selectedInfo = networkInfo.first(where: { $0.interface == selectedInterface }) {
                Text("Server IP Address: \(selectedInfo.ipAddress)")
                Text("Server Port: \(networkingViewModel.port)")
            }
            
            ForEach(selectedPlatform.instructions, id: \.self) { instruction in
                Text(instruction)
                    .padding(.bottom, 5)
            }
            
            Spacer()
        }
        .padding()
        .textSelection(.enabled) // Make the text selectable
        .onAppear {
            if let firstInterface = networkInfo.first {
                selectedInterface = firstInterface.interface
            }
        }
    }
    
    func shareCertificate() {
        let url = certificateService.certificateURL
        let sharingPicker = NSSharingServicePicker(items: [url])
        if let view = NSApplication.shared.keyWindow?.contentView {
            sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }

    func refreshNetworkInfo() {
        networkingViewModel.refreshNetworkInfo()
    }
}

//struct SetupInstructionsView_Previews: PreviewProvider {
//    static var previews: some View {
//        SetupInstructionsView(networkingViewModel: NetworkingServiceViewModel(networkingService: MockNetworkingService()), certificateService: CertificateService())
//    }
//}
