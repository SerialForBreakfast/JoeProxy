//
//  BasicConfigurationService.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/6/24.
//

import Foundation

class BasicConfigurationService: ConfigurationService {
    var proxyPort: Int = 8081 // Use a non-restricted port
    var logLevel: LogLevel = .info
}
