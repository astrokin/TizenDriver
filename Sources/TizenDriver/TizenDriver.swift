import Foundation
import Network

class TizenDriver {
        
    var ipAddress:String
    var commandClient:UDPClient
        
    init(milightProtocol:MilightProtocol, ipAddress:String){
        
        self.protocolDefinition = milightProtocol
        self.ipAddress = ipAddress
        self.commandClient = UDPClient(name: "TizenCommandClient", host: ipAddress, port: protocolDefinition.commandPort)
        self.commandClient.completionHandler = receiveCommandRespons
        self.commandClient.connect()
    }
    
    deinit {
        // perform the deinitialization
        self.commandClient.disconnect()
    }
    
    private func authenticate()->Bool{
        
    }
    
    public func executeCommand(mode:MilightMode,action:MilightAction, value:Any? = nil, zone:MilightZone? = nil){
        if authenticate(){
//        let commandSequence:[UInt8]? = composeCommandSequence(mode: mode, action:action, argument:value, zone:zone)
//        if commandSequence != nil{
//            commandClient.completionHandler = self.receiveCommandRespons
//            let dataToSend = Data(bytes: commandSequence!)
//            commandClient.send(data: dataToSend)
//        }
        }
    }
    
    func receiveCommandRespons(data:Data?, contentContext:NWConnection.ContentContext?, isComplete:Bool, error:NWError?) -> Void{
//            if let data = data, !data.isEmpty {
//                let stringRepresentation = String(data: data, encoding: .utf8)
//                let client = commandClient
//                print("ℹ️\tUDP-connection \(client.name) @IP \(client.host): \(client.port) received respons:\n" +
//                    "\t\(data as NSData) = string: \(stringRepresentation ?? "''" )")
//            }
//            if isComplete {
//                //                    self.connectionDidEnd()
//            } else if let error = error {
//                //TODO: - clean up this error handling that was in the UDP-client before
//
//                //                    self.connectionDidFail(error: error)
//            } else {
//                //                    self.prepareReceive()
//            }
//        }
    }

    
}
