//
//  NetworkInterface.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/11/24.
//

import Foundation

struct NetworkInterface: Identifiable, Hashable {
    let id = UUID()
    let interface: String
    let ipAddress: String
}
