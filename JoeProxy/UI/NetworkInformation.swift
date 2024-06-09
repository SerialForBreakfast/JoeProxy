//
//  NetworkInformation.swift
//  JoeProxy
//
//  Created by Joseph McCraw on 6/9/24.
//

import Foundation
import SystemConfiguration

class NetworkInformation {
    static let shared = NetworkInformation()
    
    private init() {}
    
    func getAllNetworkInterfaces() -> [String] {
        var interfaces: [String] = []
        
        // Use System Configuration to get network interfaces
        if let interfaceList = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] {
            for interface in interfaceList {
                if let interfaceName = SCNetworkInterfaceGetBSDName(interface) {
                    interfaces.append(interfaceName as String)
                }
            }
        }
        
        return interfaces
    }
    
    func getIPAddress(for interface: String) -> String? {
        var address: String?
        
        // Use getifaddrs to get IP address
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                
                let interfaceName = String(cString: (ptr?.pointee.ifa_name)!)
                if interfaceName == interface {
                    let addrFamily = ptr?.pointee.ifa_addr.pointee.sa_family
                    if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(ptr?.pointee.ifa_addr, socklen_t((ptr?.pointee.ifa_addr.pointee.sa_len)!), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: hostname)
                        }
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        
        return address
    }
    
    func getNetworkInformation() -> [(interface: String, ipAddress: String?)] {
        let interfaces = getAllNetworkInterfaces()
        var networkInfo: [(interface: String, ipAddress: String?)] = []
        
        for interface in interfaces {
            let ipAddress = getIPAddress(for: interface)
            networkInfo.append((interface: interface, ipAddress: ipAddress))
        }
        
        return networkInfo
    }
}
