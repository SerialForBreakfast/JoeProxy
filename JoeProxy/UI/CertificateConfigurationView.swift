import SwiftUI

struct CertificateConfigurationView: View {
    @ObservedObject var certificateService: CertificateService
    @State private var commonName = "Test"
    @State private var organization = "TestOrg"
    @State private var organizationalUnit = "TestUnit"
    @State private var country = "US"
    @State private var state = "TestState"
    @State private var locality = "TestLocality"

    var body: some View {
        VStack(alignment: .leading) {
            if certificateService.certificateExists {
                Text("Certificate exists, created on \(certificateService.certificateCreationDate ?? Date())")
                Button("Open Certificate Directory") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: certificateService.certificateURL.deletingLastPathComponent().path)
                }
            } else {
                Text("No certificate found")
            }

            TextField("Common Name", text: $commonName)
            TextField("Organization", text: $organization)
            TextField("Organizational Unit", text: $organizationalUnit)
            TextField("Country", text: $country)
            TextField("State", text: $state)
            TextField("Locality", text: $locality)

            Button("Generate Certificate") {
                certificateService.generateCertificate(
                    commonName: commonName,
                    organization: organization,
                    organizationalUnit: organizationalUnit,
                    country: country,
                    state: state,
                    locality: locality
                ) {
                    print("Generated certificate certificateExists:  \(certificateService.certificateExists)")
                }
            }
            .padding()
        }
        .padding()
        .onAppear {
            certificateService.checkCertificateExists()
        }
    }
}
