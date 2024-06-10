import SwiftUI
import NIO
import NIOHTTP1
import NIOSSL

class DependencyInitializer {
    let certificateService: CertificateService
    let configurationService: ConfigurationService
    let filteringService: FilteringService
    let loggingService: LoggingService
    let fileIO: NonBlockingFileIO
    let group: MultiThreadedEventLoopGroup
    let networkingService: DefaultNetworkingService
    let viewModel: LogViewModel
    let networkingViewModel: NetworkingServiceViewModel

    init() {
        self.certificateService = CertificateService()
        self.configurationService = BasicConfigurationService()
        self.filteringService = DefaultFilteringService(criteria: FilteringCriteria(urls: ["example.com"], filterType: .allow))
        self.loggingService = DefaultLoggingService(configurationService: self.configurationService)
        self.fileIO = NonBlockingFileIO(threadPool: NIOThreadPool(numberOfThreads: System.coreCount))
        self.group = MultiThreadedEventLoopGroup(numberOfThreads: System.coreCount)

        let eventLoop = self.group.next()
        self.networkingService = DefaultNetworkingService(
            configurationService: self.configurationService,
            filteringService: self.filteringService,
            loggingService: self.loggingService,
            certificateService: self.certificateService,
            fileIO: self.fileIO
        )

        self.viewModel = LogViewModel(loggingService: self.loggingService)
        self.networkingViewModel = NetworkingServiceViewModel(networkingService: self.networkingService)
    }
}

@main
struct JoeProxyApp: App {
    init() {
        self.init(initializer: DependencyInitializer())
    }
    
    @StateObject var certificateService: CertificateService
    @StateObject private var viewModel: LogViewModel
    @StateObject private var networkingViewModel: NetworkingServiceViewModel
    @State private var showSetupInstructions = false

    init(initializer: DependencyInitializer = DependencyInitializer()) {
        _certificateService = StateObject(wrappedValue: initializer.certificateService)
        _viewModel = StateObject(wrappedValue: initializer.viewModel)
        _networkingViewModel = StateObject(wrappedValue: initializer.networkingViewModel)
    }

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
                    showSetupInstructions = true
                }
                .keyboardShortcut("I", modifiers: [.command, .option])
            }
            CommandGroup(replacing: .newItem) {
                Button("Open Certificate Configuration") {
                    openCertificateConfigurationWindow()
                }
                .keyboardShortcut("N", modifiers: [.command])
            }
        }
    }
}
