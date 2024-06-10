import Foundation
import SwiftUI

extension JoeProxyApp {
    func openInstructionsWindow() {
        let instructionView = SetupInstructionsView(certificateService: certificateService)
        let hostingController = NSHostingController(rootView: instructionView)
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 600, height: 400))
        window.styleMask = [.titled, .closable, .resizable]
        window.title = "Setup Instructions"
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
    }
    
    func openCertificateConfigurationWindow() {
        let certificateConfigurationView = CertificateConfigurationView(certificateService: certificateService)
        let hostingController = NSHostingController(rootView: certificateConfigurationView)
        let window = NSWindow(contentViewController: hostingController)
        window.setContentSize(NSSize(width: 400, height: 300))
        window.styleMask = [.titled, .closable, .resizable]
        window.title = "Certificate Configuration"
        window.isReleasedWhenClosed = false
        window.makeKeyAndOrderFront(nil)
    }
}
