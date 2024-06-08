import SwiftUI

@main
struct JoeProxyApp: App {
    @State private var certificateService = CertificateService()
    @State private var networkingService: DefaultNetworkingService
    @State private var loggingService: DefaultLoggingService

    init() {
        let configurationService = BasicConfigurationService()
        let filteringCriteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
        let filteringService = DefaultFilteringService(criteria: filteringCriteria)
        let loggingService = DefaultLoggingService(configurationService: configurationService)
        let certificateService = CertificateService()
        let networkingService = DefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService, certificateService: certificateService)
        _loggingService = State(initialValue: loggingService)
        _networkingService = State(initialValue: networkingService)
        _certificateService = State(initialValue: certificateService)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(loggingService: loggingService)
                .onAppear {
                    do {
                        try networkingService.startServer()
                    } catch {
                        loggingService.log("Failed to start server: \(error)", level: .error)
                    }
                }
                .onDisappear {
                    do {
                        try networkingService.stopServer()
                    } catch {
                        loggingService.log("Failed to stop server: \(error)", level: .error)
                    }
                }
        }
        .commands {
            CommandMenu("Actions") {
                Button("Generate Certificate") {
                    certificateService.generateCertificate()
                }
                Button("Start Server") {
                    do {
                        try networkingService.startServer()
                    } catch {
                        loggingService.log("Failed to start server: \(error)", level: .error)
                    }
                }
                Button("Stop Server") {
                    do {
                        try networkingService.stopServer()
                    } catch {
                        loggingService.log("Failed to stop server: \(error)", level: .error)
                    }
                }
            }
        }
    }
}
