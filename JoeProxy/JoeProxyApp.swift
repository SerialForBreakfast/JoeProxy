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



enum UIPrototype {
    case old
    case prototypeA
}

@main
struct JoeProxyApp: App {
    init() {
        self.init(initializer: DependencyInitializer())
    }
    
    @StateObject var certificateService: CertificateService
    @StateObject private var viewModel: LogViewModel
    @StateObject var networkingViewModel: NetworkingServiceViewModel
    @State private var showSetupInstructions = false
    @State private var showInspectorView = false
    @State private var showCertificateConfiguration = false
    @State private var selectedUI: UIPrototype = .prototypeA  // Default to new prototype

    init(initializer: DependencyInitializer = DependencyInitializer()) {
        _certificateService = StateObject(wrappedValue: initializer.certificateService)
        _viewModel = StateObject(wrappedValue: initializer.viewModel)
        _networkingViewModel = StateObject(wrappedValue: initializer.networkingViewModel)
    }

    var body: some Scene {
        WindowGroup {
            switch selectedUI {
            case .old:
                ContentView(
                    viewModel: viewModel,
                    certificateService: certificateService,
                    networkingViewModel: networkingViewModel
                )
            case .prototypeA:
                PrototypeAView(
                    viewModel: viewModel,
                    networkingViewModel: networkingViewModel
                )
                .onAppear {
                    showSetupInstructions = true
                    showInspectorView = true
                    showCertificateConfiguration = true
                }
            }
        }
        .commands {
            CommandGroup(replacing: .help) {
                Button("Setup Instructions") {
                    showSetupInstructions = true
                }
                .keyboardShortcut("I", modifiers: [.command, .option])
            }
            CommandGroup(replacing: .newItem) {
                Button("Open Inspector View") {
                    showInspectorView = true
                }
                .keyboardShortcut("I", modifiers: [.command])
                Button("Open Certificate Configuration") {
                    showCertificateConfiguration = true
                }
                .keyboardShortcut("C", modifiers: [.command])
            }
        }
//
//        if showSetupInstructions {
            WindowGroup("Setup Instructions") {
                SetupInstructionView(networkingViewModel: networkingViewModel)
                    .frame(minWidth: 600, minHeight: 400)
                    .onDisappear {
                        showSetupInstructions = false
                    }
            }
//        }
//
//        if showInspectorView {
        WindowGroup("Inspector View") {
            InspectorView(logEntry: viewModel.selectedLogEntry ?? LogEntry(timestamp: Date().addingTimeInterval(-180), host: "api.example.com", path: "/api/data/1", request: "DELETE /api/data/1", headers: "Host: api.example.com\nAuthorization: Bearer token", response: "204 No Content", responseBody: "", statusCode: 204))
                .frame(minWidth: 600, minHeight: 400)
                .onDisappear {
                    showInspectorView = false
                }
        }
//        }
//
//        if showCertificateConfiguration {
            WindowGroup("Certificate Configuration") {
                CertificateConfigurationView(certificateService: certificateService)
                    .frame(minWidth: 600, minHeight: 400)
                    .onDisappear {
                        showCertificateConfiguration = false
                    }
            }
//        }
    }
}
