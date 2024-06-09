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
    @Published var ipAddress: String?
    @Published var port: Int = 8443
    @Published var isServerRunning: Bool = false
    private var networkingService: DefaultNetworkingService
    @Published var networkInfo: [(interface: String, ipAddress: String?)] = []

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
    func refreshNetworkInfo() {
        self.networkInfo = NetworkInformation.shared.getNetworkInformation()
        if let firstInfo = networkInfo.first {
            self.ipAddress = firstInfo.ipAddress
        }
    }
}
