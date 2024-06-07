//
//  JoeProxyApp.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import SwiftUI

@main
struct JoeProxyApp: App {
    var body: some Scene {
        WindowGroup {
            let configurationService = BasicConfigurationService()
            let filteringCriteria = FilteringCriteria(urls: ["example.com"], filterType: .allow)
            let filteringService = DefaultFilteringService(criteria: filteringCriteria)
            let loggingService = DefaultLoggingService(configurationService: configurationService)
            let networkingService = DefaultNetworkingService(configurationService: configurationService, filteringService: filteringService, loggingService: loggingService)
            
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
    }
}
