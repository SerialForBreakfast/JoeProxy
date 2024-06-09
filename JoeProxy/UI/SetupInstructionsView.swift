//
//  SetupInstructionsView.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/9/24.
//

import SwiftUI

enum Platform: String, CaseIterable, Identifiable {
    case iOS, tvOS, macOS
    
    var id: String { self.rawValue }
    
    var instructions: [String] {
        switch self {
        case .iOS:
            return [
                "1. Ensure the SSL server is running.",
                "2. Install the client certificate on your iOS device:",
                "   a. Download the certificate file.",
                "   b. Open the Settings app.",
                "   c. Go to General > Profiles & Device Management.",
                "   d. Import the certificate file.",
                "   e. Ensure the certificate is set to 'Always Trust'.",
                "3. Configure your client application to use the certificate for SSL connections.",
                "4. Connect to the SSL server using the appropriate client settings."
            ]
        case .tvOS:
            return [
                "1. Ensure the SSL server is running.",
                "2. Install the client certificate on your tvOS device:",
                "   a. Download the certificate file.",
                "   b. Use Apple Configurator or another tool to install the certificate on your tvOS device.",
                "   c. Ensure the certificate is set to 'Always Trust'.",
                "3. Configure your client application to use the certificate for SSL connections.",
                "4. Connect to the SSL server using the appropriate client settings."
            ]
        case .macOS:
            return [
                "1. Ensure the SSL server is running.",
                "2. Install the client certificate on your macOS device:",
                "   a. Download the certificate file.",
                "   b. Open the Keychain Access application.",
                "   c. Import the certificate file into the 'System' keychain.",
                "   d. Ensure the certificate is set to 'Always Trust'.",
                "3. Configure your client application to use the certificate for SSL connections.",
                "4. Connect to the SSL server using the appropriate client settings."
            ]
        }
    }
}

struct SetupInstructionsView: View {
    @State private var selectedPlatform: Platform = .iOS
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
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
            
            ForEach(selectedPlatform.instructions, id: \.self) { instruction in
                Text(instruction)
                    .padding(.bottom, 5)
            }
            
            Spacer()
        }
        .padding()
    }
}

struct SetupInstructionsView_Previews: PreviewProvider {
    static var previews: some View {
        SetupInstructionsView()
    }
}
