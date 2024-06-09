import Network
import Combine

class NetworkMonitor: ObservableObject {
    @Published var interfaces: [NWInterface.InterfaceType] = []
    @Published var currentInterface: NWInterface.InterfaceType?
    @Published var isExpensive: Bool = false
    
    private var monitor: NWPathMonitor?
    private var queue = DispatchQueue.global(qos: .background)
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        monitor = NWPathMonitor()
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.interfaces = path.availableInterfaces.map { $0.type }
                self?.currentInterface = path.availableInterfaces.first?.type
                self?.isExpensive = path.isExpensive
            }
        }
        monitor?.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor?.cancel()
    }
}


