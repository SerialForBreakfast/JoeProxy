import SwiftUI
import os.log

@main
struct JoeProxyApp: App {
    @StateObject private var certificateService = CertificateService()
    private let configurationService = BasicConfigurationService()
    private let filteringService = DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow))
    private let loggingService = DefaultLoggingService(configurationService: BasicConfigurationService())
    private let networkingService: DefaultNetworkingService
    @StateObject private var viewModel: LogViewModel
    @StateObject private var networkingViewModel: NetworkingServiceViewModel

    init() {
        print("Initializing JoeProxyApp...")
        let filteringCriteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: filteringCriteria)
        let loggingService = DefaultLoggingService(configurationService: BasicConfigurationService())
        let certificateService = CertificateService()
        let networkingService = DefaultNetworkingService(
            configurationService: BasicConfigurationService(),
            filteringService: filteringService,
            loggingService: loggingService,
            certificateService: certificateService
        )
        _viewModel = StateObject(wrappedValue: LogViewModel(loggingService: loggingService))
        _networkingViewModel = StateObject(wrappedValue: NetworkingServiceViewModel(networkingService: networkingService))
        self.networkingService = networkingService
        print("JoeProxyApp initialized.")
        os_log("Application started", log: OSLog.default, type: .debug)

    }

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: viewModel,
                certificateService: certificateService,
                networkingViewModel: networkingViewModel
            )
            .onAppear {
                print("ContentView appeared.")
            }
            .onDisappear {
                print("ContentView disappeared.")
                do {
                    try networkingViewModel.stopServer()
                    print("Server stopped.")
                } catch {
                    loggingService.log("Failed to stop server: \(error)", level: .error)
                    print("Failed to stop server: \(error)")
                }
            }
        }
    }
}

