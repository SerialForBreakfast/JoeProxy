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
    var networkingService: DefaultNetworkingService
    @Published var networkInformation = NetworkInformation.shared
    @Published var networkInfo: [(interface: String, ipAddress: String?)] = []
    
    init(networkingService: DefaultNetworkingService) {
        self.networkingService = networkingService
    }
    
    func startServer() {
        do {
            try networkingService.startServer(completion: { [weak self] result in
                self?.isServerRunning = true
                print("Started server")
            })
        } catch {
            print("Failed to start server: \(error)")
        }
    }
    
    func stopServer() {
        do {
            try networkingService.stopServer(completion: { [weak self] result in
                self?.isServerRunning = false
            })
        } catch {
            print("Failed to stop server: \(error)")
        }
    }
    
    func refreshNetworkInfo() {
        self.networkInformation.refreshNetworkInfo()
        if let firstInfo = networkInformation.networkInfo.first {
            self.ipAddress = firstInfo.ipAddress
        }
    }
}
