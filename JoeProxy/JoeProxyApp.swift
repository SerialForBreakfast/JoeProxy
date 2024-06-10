import SwiftUI

@main
struct JoeProxyApp: App {
    @StateObject private var certificateService = CertificateService()
    private let configurationService = BasicConfigurationService()
    private let filteringService = DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow))
    private let loggingService = DefaultLoggingService(configurationService: BasicConfigurationService())
    private let networkingService = DefaultNetworkingService(configurationService: BasicConfigurationService(), filteringService: DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow)), loggingService: DefaultLoggingService(configurationService: BasicConfigurationService()), certificateService: CertificateService())
    @StateObject private var viewModel = LogViewModel(loggingService: DefaultLoggingService(configurationService: BasicConfigurationService()))
    @StateObject private var networkingViewModel = NetworkingServiceViewModel(networkingService: DefaultNetworkingService(configurationService: BasicConfigurationService(), filteringService: DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow)), loggingService: DefaultLoggingService(configurationService: BasicConfigurationService()), certificateService: CertificateService()))
    
    @State private var showSetupInstructions = false
    
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: viewModel,
                certificateService: certificateService,
                networkingViewModel: networkingViewModel
            )
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Setup Instructions") {
                    openInstructionsWindow()
                }
                .keyboardShortcut("I", modifiers: [.command, .option])
            }
        }
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("Open Certificate Configuration") {
                    openCertificateConfigurationWindow()
                }
                .keyboardShortcut("N", modifiers: [.command])
            }
        }
    }
    
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
