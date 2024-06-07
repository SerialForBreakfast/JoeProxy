//
//  MockOpenSSLInstaller.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/7/24.
//

import Foundation

class MockOpenSSLInstaller: OpenSSLInstaller {
    var shouldSucceed: Bool

    init(shouldSucceed: Bool = true) {
        self.shouldSucceed = shouldSucceed
    }

    override func installOpenSSL() -> Bool {
        print("Mock installation of OpenSSL. Should succeed: \(shouldSucceed)")
        return shouldSucceed
    }

    override func shell(_ command: String) throws -> String {
        return "Mock shell command executed: \(command)"
    }
}
