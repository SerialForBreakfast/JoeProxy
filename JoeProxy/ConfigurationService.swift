//
//  ConfigurationService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation

protocol ConfigurationService {
    var proxyPort: Int { get set }
    var logLevel: LogLevel { get set }
    // Add more configuration settings as needed
}

enum LogLevel: String {
    case debug, info, warning, error
}

class DefaultConfigurationService: ConfigurationService {
    private let userDefaults: UserDefaults
    
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }
    
    var proxyPort: Int {
        get { return userDefaults.integer(forKey: "proxyPort") }
        set { userDefaults.set(newValue, forKey: "proxyPort") }
    }
    
    var logLevel: LogLevel {
        get {
            guard let logLevel = userDefaults.string(forKey: "logLevel"),
                  let level = LogLevel(rawValue: logLevel) else {
                return .info
            }
            return level
        }
        set { userDefaults.set(newValue.rawValue, forKey: "logLevel") }
    }
}
