import SwiftUI

struct SetupInstructionsView: View {
    @State private var selectedPlatform: Platform = .iOS
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel
    private let certificateService: CertificateService
    
    init(networkingViewModel: NetworkingServiceViewModel, certificateService: CertificateService) {
        self.networkingViewModel = networkingViewModel
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
                    networkingViewModel.refreshNetworkInfo()
                }
                .padding()
            }
            Text("Setup Instructions")
                .font(.title)
                .padding(.bottom, 20)
            
            Text("Server IP Address: \(networkingViewModel.ipAddress ?? "Unknown")")
                .padding(.bottom, 5)
            Text("Server Port: \(networkingViewModel.port)")
                .padding(.bottom, 20)
            
            Picker("Select Platform", selection: $selectedPlatform) {
                ForEach(Platform.allCases) { platform in
                    Text(platform.rawValue).tag(platform)
                }
            }
            .pickerStyle(SegmentedPickerStyle())
            .padding(.bottom, 20)
            
            ForEach(selectedPlatform.instructions, id: \.self) { instruction in
                Text(instruction)
                    .padding(.bottom, 5)
            }
            
            Spacer()
        }
        .padding()
    }
    
    func shareCertificate() {
        let url = certificateService.certificateURL
        let sharingPicker = NSSharingServicePicker(items: [url])
        if let view = NSApplication.shared.keyWindow?.contentView {
            sharingPicker.show(relativeTo: .zero, of: view, preferredEdge: .minY)
        }
    }
}

struct SetupInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SetupInstructionsView(
            networkingViewModel: NetworkingServiceViewModel(
                networkingService: DefaultNetworkingService(
                    configurationService: BasicConfigurationService(),
                    filteringService: DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow)),
                    loggingService: DefaultLoggingService(configurationService: BasicConfigurationService()),
                    certificateService: CertificateService()
                )
            ),
            certificateService: CertificateService()
        )
    }
}
