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

    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: viewModel,
                certificateService: certificateService,
                networkingViewModel: networkingViewModel
            )
            .onAppear {
                print("ContentView onAppear called.")
            }
        }
    }
}
