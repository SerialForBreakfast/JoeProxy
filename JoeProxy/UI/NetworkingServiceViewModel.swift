//
//  NetworkingServiceViewModel.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/8/24.
//

import Foundation
import SwiftUI
import Combine

class NetworkingServiceViewModel: ObservableObject {
    @Published var isServerRunning: Bool = false
    private var networkingService: DefaultNetworkingService

    init(networkingService: DefaultNetworkingService) {
        self.networkingService = networkingService
    }

    func startServer() {
        do {
            try networkingService.startServer()
            isServerRunning = true
        } catch {
            print("Failed to start server: \(error)")
        }
    }

    func stopServer() {
        do {
            try networkingService.stopServer()
            isServerRunning = false
        } catch {
            print("Failed to stop server: \(error)")
        }
    }
}
