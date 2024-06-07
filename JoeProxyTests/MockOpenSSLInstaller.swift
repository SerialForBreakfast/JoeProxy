//
//  MockOpenSSLInstaller.swift
//  JoeProxyTests
//
//  Created by Joseph McCraw on 6/7/24.
//

import Foundation
@testable import JoeProxy

class MockOpenSSLInstaller: OpenSSLInstaller {
    var installCalled = false
    var findCalled = false
    
    override func installOpenSSL() {
        installCalled = true
        print("Mock OpenSSL installation called")
    }
    
    override func findOpenSSL() -> String? {
        findCalled = true
        print("Mock OpenSSL find called")
        return "/mock/path/to/openssl"
    }
}
