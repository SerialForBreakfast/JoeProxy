//
//  MockCertificateService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/7/24.
//

import Foundation
import Combine

class MockCertificateService: CertificateService {
    override func generateCertificate(commonName: String? = nil, organization: String? = nil, organizationalUnit: String? = nil, country: String? = nil, state: String? = nil, locality: String? = nil, completion: (() -> Void)? = nil) {
        DispatchQueue.global(qos: .background).async {
            print("Mock certificate generation started...")
            self.certificateExists = true
            self.certificateCreationDate = Date()
            DispatchQueue.main.async {
                print("Mock certificate generation completed.")
            }
        }
    }
    
    override func checkCertificateExists() {
        self.certificateExists = false
        self.certificateCreationDate = nil
    }
}


// Mock Networking Service to avoid actual network operations
class MockNetworkingService: NetworkingService {
    func startServer(completion: @escaping (Result<Void, any Error>) -> Void) throws {
        let error = NSError()
        completion(.failure(error))
    }
    
    func stopServer(completion: @escaping (Result<Void, any Error>) -> Void) throws {
        completion(.success(()))
    }
    
    private let configurationService: ConfigurationService
    private var isServerRunning = false
    
    init(configurationService: ConfigurationService) {
        self.configurationService = configurationService
    }
    
    func startServer() throws {
        guard !isServerRunning else { throw NSError(domain: "Server already running", code: 1, userInfo: nil) }
        isServerRunning = true
        print("Mock server started on port \(configurationService.proxyPort)")
    }
    
    func stopServer() throws {
        guard isServerRunning else { throw NSError(domain: "Server not running", code: 1, userInfo: nil) }
        isServerRunning = false
        print("Mock server stopped.")
    }
}
