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
    @Published var selectedInterface: NetworkInterface?
    @Published var networkInfo: [NetworkInterface] = []
    var networkingService: DefaultNetworkingService

    init(networkingService: DefaultNetworkingService) {
        self.networkingService = networkingService
        refreshNetworkInfo()
    }

    func startServer() {
        do {
            try networkingService.startServer(completion: { [weak self] result in
                self?.isServerRunning = true
                self?.ipAddress = self?.networkingService.serverIP
                self?.port = self?.networkingService.serverPort ?? 8443
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
                print("Stopped server")
            })
        } catch {
            print("Failed to stop server: \(error)")
        }
    }

    func refreshNetworkInfo() {
        networkInfo = NetworkInformation.shared.networkInfo
        if let firstInfo = networkInfo.first {
            selectedInterface = firstInfo
            ipAddress = firstInfo.ipAddress
        }
    }
}
