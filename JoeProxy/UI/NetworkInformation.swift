import Foundation
import SystemConfiguration

class NetworkInformation {
    static let shared = NetworkInformation()

    func getNetworkInformation() -> [(interface: String, ipAddress: String)] {
        var addresses = [(interface: String, ipAddress: String)]()
        
        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                let interface = ptr!.pointee
                let addrFamily = interface.ifa_addr.pointee.sa_family
                
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: interface.ifa_name)
                    var address: String?
                    
                    if addrFamily == UInt8(AF_INET) {
                        var addr = sockaddr_in()
                        memcpy(&addr, interface.ifa_addr, MemoryLayout<sockaddr_in>.size)
                        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(interface.ifa_addr, socklen_t(MemoryLayout<sockaddr_in>.size), &buffer, socklen_t(buffer.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: buffer)
                        }
                    } else if addrFamily == UInt8(AF_INET6) {
                        var addr = sockaddr_in6()
                        memcpy(&addr, interface.ifa_addr, MemoryLayout<sockaddr_in6>.size)
                        var buffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(interface.ifa_addr, socklen_t(MemoryLayout<sockaddr_in6>.size), &buffer, socklen_t(buffer.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                            address = String(cString: buffer)
                        }
                    }
                    
                    if let address = address, !address.starts(with: "127.") {
                        addresses.append((interface: name, ipAddress: address))
                    }
                }
                
                ptr = ptr!.pointee.ifa_next
            }
            freeifaddrs(ifaddr)
        }
        
        return addresses
    }
}
