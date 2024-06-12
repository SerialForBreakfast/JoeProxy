import Foundation
import SwiftUI
import Combine

class NetworkingServiceViewModel: ObservableObject {
    @Published var ipAddress: String?
    @Published var port: Int?
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
                guard let self = self else { return }
                switch result {
                case .success:
                    self.isServerRunning = true
                    self.ipAddress = self.networkingService.serverIP
                    self.port = self.networkingService.serverPort
                    print("Started server at ipAddress: \(self.networkingService.serverIP ?? "nil") \(self.networkingService.serverPort)")
                case .failure(let error):
                    print("Failed to start server: \(error)")
                }
            })
        } catch {
            print("Failed to start server: \(error)")
        }
    }

    func stopServer() {
        do {
            try networkingService.stopServer(completion: { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success:
                    self.isServerRunning = false
                    print("Stopped server")
                case .failure(let error):
                    print("Failed to stop server: \(error)")
                }
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
