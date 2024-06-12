import SwiftUI

struct PrototypeBView: View {
    @EnvironmentObject var logStateStore: LogStateStore
    @ObservedObject var certificateService: CertificateService
    @ObservedObject var networkingViewModel: NetworkingServiceViewModel

    var body: some View {
        VStack {
            HStack {
                FilteringLogView()
                    .frame(minWidth: 300, minHeight: 300)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environmentObject(logStateStore)

                InspectorView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .environmentObject(logStateStore)
            }
            HStack {
                CertificateConfigurationView(certificateService: certificateService)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                SetupInstructionView(networkingViewModel: networkingViewModel)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
