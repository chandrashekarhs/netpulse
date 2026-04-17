import Network

class NetworkMonitor {
    var onStatusChange: ((Bool) -> Void)?
    private(set) var isConnected = false
    private let monitor = NWPathMonitor()

    func start() {
        monitor.pathUpdateHandler = { [weak self] path in
            let connected = path.status == .satisfied
            DispatchQueue.main.async {
                self?.isConnected = connected
                self?.onStatusChange?(connected)
            }
        }
        monitor.start(queue: DispatchQueue(label: "net.monitor"))
    }
}
