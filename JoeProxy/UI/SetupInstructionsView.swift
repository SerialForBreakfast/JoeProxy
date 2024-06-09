import SwiftUI

struct SetupInstructionsView: View {
    @State private var selectedPlatform: Platform = .iOS
    @State private var selectedInterface: String = ""
    @ObservedObject private var networkInformation = NetworkInformation.shared
    private let certificateService: CertificateService
    
    init(certificateService: CertificateService) {
        self.certificateService = certificateService
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Button("Share Certificate") {
                    shareCertificate()
                }
                .padding()
                
                Button("Refresh Network Information") {
                    networkInformation.refreshNetworkInfo()
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
            
            Picker("Select Interface", selection: $selectedInterface) {
                ForEach(networkInformation.networkInfo, id: \.interface) { info in
                    Text(info.interface).tag(info.interface)
                }
            }
            .pickerStyle(MenuPickerStyle())
            .padding(.bottom, 20)
            
            Text("Server IP Address: \(networkInformation.networkInfo.first { $0.interface == selectedInterface }?.ipAddress ?? "N/A")")
            Text("Server Port: 8443")
                .padding(.bottom, 20)
            
            ForEach(selectedPlatform.instructions, id: \.self) { instruction in
                Text(instruction)
                    .padding(.bottom, 5)
                    .textSelection(.enabled)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func shareCertificate() {
        let url = certificateService.certificateURL
        let sharingPicker = NSSharingServicePicker(items: [url])
        if let view = NSApplication.shared.keyWindow?.contentView {
            sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
}

struct SetupInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SetupInstructionsView(certificateService: CertificateService())
    }
}
