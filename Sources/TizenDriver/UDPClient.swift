import Foundation
import Network

@available(macOS 10.14, *)
class UDPClient {
    
    let maxUDPPackageSize = 65535 //The UDP maximum package size is 64K
    let name: String
    let host: NWEndpoint.Host
    let port: NWEndpoint.Port
    let udpConnection: NWConnection
    var completionHandler:((Data?, NWConnection.ContentContext?, Bool, NWError?) -> Void)! = nil
    
    let queue = DispatchQueue(label: "UDP-client connection Q")
    var didStopCallback: ((Error?) -> Void)? = nil
    
    init(name: String, host: String, port: UInt16){
        self.name = name
        self.host = NWEndpoint.Host(host)
        self.port = NWEndpoint.Port(rawValue: port)!
        self.udpConnection = NWConnection(host: self.host, port: self.port, using: .udp)
        self.udpConnection.stateUpdateHandler = self.stateDidChange(to:)
    }
    
    func connect() {
        udpConnection.start(queue: queue)
        print("ℹ️\tUDP-connection made with @IP \(host): \(port)")
    }
    
    func disconnect() {
        stop(error: nil)
        print("ℹ️\tUDP-connection closed with @IP \(host): \(port)")
    }
    
    func send(data: Data) {
        self.udpConnection.receive(minimumIncompleteLength: 1, maximumLength: maxUDPPackageSize, completion: self.completionHandler)
        udpConnection.send(content: data, completion: .contentProcessed( { error in
            if let error = error {
                self.connectionDidFail(error: error)
                return
            }
        }))
        print("ℹ️\tDataSentTo @IP \(host): \(port): \(data as NSData)")
    }
    
    
    // MARK: - Subroutines
    
    private func stateDidChange(to state: NWConnection.State) {
        switch state {
        case .waiting(let error):
            connectionDidFail(error: error)
        case .ready:
            print("ℹ️\tUDP-connection @IP \(host): \(port) ready")
        case .failed(let error):
            connectionDidFail(error: error)
        default:
            break
        }
    }
    
    private func connectionDidFail(error: Error) {
        print("ℹ️\tUDP-connection @IP \(host): \(port) did fail, error: \(error)")
        self.stop(error: error)
    }
    
    private func connectionDidEnd() {
        print("ℹ️\tUDP-connection @IP \(host): \(port) did end")
        self.stop(error: nil)
    }
    
    private func stop(error: Error?) {
        udpConnection.stateUpdateHandler = nil
        udpConnection.cancel()
        if let didStopCallback = self.didStopCallback {
            self.didStopCallback = nil
            didStopCallback(error)
        }
    }
    
    func didStopCallback(error: Error?) {
        if error == nil {
            exit(EXIT_SUCCESS)
        } else {
            exit(EXIT_FAILURE)
        }
    }
    
}
