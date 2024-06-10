//
//  CertificateConfigurationView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/9/24.
//

import Foundation
import SwiftUI

struct CertificateConfigurationView: View {
    @ObservedObject var certificateService: CertificateService
    @State private var commonName = ""
    @State private var organization = ""
    @State private var organizationalUnit = ""
    @State private var country = ""
    @State private var state = ""
    @State private var locality = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            TextField("Common Name (CN)", text: $commonName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Organization (O)", text: $organization)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Organizational Unit (OU)", text: $organizationalUnit)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Country (C)", text: $country)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("State (ST)", text: $state)
                .textFieldStyle(RoundedBorderTextFieldStyle())
            TextField("Locality (L)", text: $locality)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button(action: {
                certificateService.generateCertificate(commonName: commonName, organization: organization, organizationalUnit: organizationalUnit, country: country, state: state, locality: locality)
            }) {
                Text("Generate Certificate")
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.top, 20)

            Spacer()
        }
        .padding()
    }
}

struct CertificateConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        CertificateConfigurationView(certificateService: CertificateService())
    }
}
