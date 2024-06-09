import Network
import Foundation

class NetworkInformation: ObservableObject {
    static let shared = NetworkInformation()
    
    @Published var networkInfo: [(interface: String, ipAddress: String)] = []
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue.global(qos: .background)
    
    private init() {
        refreshNetworkInfo()
    }
    
    func refreshNetworkInfo() {
        var interfaces: [NWInterface] = []
        monitor.pathUpdateHandler = { path in
            interfaces = path.availableInterfaces
            DispatchQueue.main.async {
                self.networkInfo = interfaces.compactMap { interface in
                    let ipAddress = self.getIPAddress(for: interface)
                    return (interface: interface.name ?? "Unknown", ipAddress: ipAddress ?? "N/A")
                }
            }
        }
        monitor.start(queue: queue)
    }
    
    private func getIPAddress(for interface: NWInterface) -> String? {
        var address: String?
        var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
        if getifaddrs(&ifaddr) == 0 {
            var ptr = ifaddr
            while ptr != nil {
                defer { ptr = ptr?.pointee.ifa_next }
                guard let interfacePtr = ptr else { return nil }
                let addrFamily = interfacePtr.pointee.ifa_addr.pointee.sa_family
                if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                    let name = String(cString: interfacePtr.pointee.ifa_name)
                    if name == interface.name {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        getnameinfo(interfacePtr.pointee.ifa_addr, socklen_t(interfacePtr.pointee.ifa_addr.pointee.sa_len),
                                    &hostname, socklen_t(hostname.count),
                                    nil, socklen_t(0), NI_NUMERICHOST)
                        address = String(cString: hostname)
                    }
                }
            }
            freeifaddrs(ifaddr)
        }
        return address
    }
}
