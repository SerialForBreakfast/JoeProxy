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
        VStack {
            if certificateService.certificateExists {
                Text("Certificate exists, created on \(certificateService.certificateCreationDate ?? Date())")
                Button("Open Certificate Directory") {
                    NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: certificateService.certificateURL.deletingLastPathComponent().path)
                }
            } else {
                Text("No certificate found")
            }

            Button("Generate Certificate") {
                do {
                    try certificateService.generateCertificate {
                        print("Generated certificate certificateExists:  \(certificateService.certificateExists)")
                    }
                } catch {
                    print("Failed to generate certificate: \(error)")
                }
            }
            .padding()
        }
        .onAppear {
            certificateService.checkCertificateExists()
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

struct CertificateConfigurationView_Previews: PreviewProvider {
    static var previews: some View {
        CertificateConfigurationView(certificateService: CertificateService())
    }
}
