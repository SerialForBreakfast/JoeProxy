//
//  MockCertificateService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/7/24.
//

import Foundation
import Combine

class MockCertificateService: CertificateService {
    override func generateCertificate() {
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
