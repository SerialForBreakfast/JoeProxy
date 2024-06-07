//
//  MockOpenSSLInstaller.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/7/24.
//

import Foundation

class MockOpenSSLInstaller: OpenSSLInstaller {
    var installCalled = false
    
    override func installOpenSSL() {
        installCalled = true
        print("Mock OpenSSL installation called")
    }
}
