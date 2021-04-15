import Foundation
import JVCocoa

public class TizenDriver:WebSocketDelegate{
    
    // MARK: - Setup
    let tvName:String
    let macAddress:String
    let ipAddress:String
    let port:Int
    let deviceName:String
    
    private var urlRequest:URLRequest{
        let base64DeviceName = Data(deviceName.utf8).base64EncodedString()
        let connectionString = "wss://\(ipAddress):\(port)/api/v2/channels/samsung.remote.control?name=\(base64DeviceName)&token=\(deviceToken ?? 0)"
        print("Connectionstring:\n\(connectionString)")
        var request =  URLRequest(url: URL(string: connectionString)!)
        request.timeoutInterval = 5
        return request
    }
    
    var webSocket:WebSocket! = nil
    
	var pairingInfo:[String:[String:Int]] = [:]
	var deviceToken:Int!
    
    public enum PowerState:Int, Comparable{
        
        case undefined
        case poweredOff
        case poweringDown
        case poweringUp
        case poweredOn
        
        // Conform to comparable
        public static func < (a: PowerState, b: PowerState) -> Bool {
            return a.rawValue < b.rawValue
        }
    }
    
    public var powerState:PowerState! = nil{
        
        didSet{
            
            switch powerState {
            case .poweredOff:
                if powerState != oldValue{
                    print("🔳:\t '\(tvName)' powered off")
                }
            case .poweringDown:
                if let previousState = oldValue{
                    if (powerState != previousState) && (previousState > .poweringDown) {
                        send(commandKey: .KEY_POWER)
                    }
                }
            case .poweringUp:
                if let previousState = oldValue{
                    if (powerState != previousState) && (previousState < .poweringUp){
                        
                        // Perform a WakeOnLan
                        let tv = Awake.Device(MAC: macAddress, BroadcastAddr: "255.255.255.255", Port: 9)
                        _ = Awake.target(device: tv)
                        connectionState = .connecting
                    }
                }
            case .poweredOn:
                
                if powerState != oldValue{
                    print("🔲:\t '\(tvName)' powered on")
                }
                
            default:
                break
            }
            
        }
    }
    
    private enum ConnectionState:Int, Comparable{
        
        case undefined
        case disconnected
        case disconnecting
        case connecting
        case connected
        case paired
        
        
        // Conform to comparable
        public static func < (a: ConnectionState, b: ConnectionState) -> Bool {
            return a.rawValue < b.rawValue
        }
    }
    
    private var connectionState:ConnectionState! = nil{
        
        didSet{
            
            switch connectionState {
            
            case .disconnected:
                
                if connectionState != oldValue{
                    print(":\t \(deviceName) disconnected from '\(tvName)'")
                }
                
            case .disconnecting:
                
                if connectionState != oldValue{
                    webSocket.disconnect()
                }
                
            case .connecting:
                
                if connectionState != oldValue{
                    webSocket = WebSocket(urlRequest: urlRequest, delegate: self)
                    webSocket.connect()
                }
                
            case .connected:
                
                if connectionState != oldValue{
                    print("🔗:\t \(deviceName) connected with '\(tvName)'")
                }
                
            case .paired:
                
				if connectionState != oldValue, let token = self.deviceToken{
                    print("✅:\t \(deviceName) paired with '\(tvName)' using key \(token)")
                }
                // SEND QUEUED COMMANDS ONCE PAIRING SUCCEEDED!!
                if !commandQueue.isEmpty{
                    queue(commands:)()
                }
                
            default:
                break
            }
            
            
        }
    }
    var commandQueue:[TizenCommand] = []
    
    public init(tvName:String, macAddress:String, ipAddress:String, port:Int = 8002, deviceName:String){
        
        self.tvName = tvName
        self.macAddress = macAddress
        self.ipAddress = ipAddress
        self.port = port
        self.deviceName = deviceName
        
		self.pairingInfo = getPreference(forKeyPath: .tizenSettings, .pairingInfo) ?? [:]
		self.deviceToken = self.pairingInfo[tvName]?[deviceName]
		print("ℹ️:\t Token:\(self.deviceToken) from prefs")

    }
    
    deinit {
        // perform the deinitialization
        connectionState = .disconnecting
        powerState = .poweringDown
    }
    
    // MARK: - Remotes Functions
    public func cycleTroughChannels(){
        let numberOfChannels = 6
        gotoChannel(1)
        for _ in 1...numberOfChannels{
            queue(commands:[.KEY_CHUP])
            sleep(3)
        }
    }
    
    public func gotoChannel(_ channelNumber:Int){
        if let keyCommand = TizenCommand(rawValue:"KEY_\(channelNumber)"){
            queue(commands:[keyCommand, .KEY_ENTER] )
        }
    }
    
    
    public func queue(commands commandKeys:[TizenCommand]? = nil){
        
        if let newCommands = commandKeys{
            commandQueue += newCommands
        }
        
        guard (connectionState == .paired) else{
            powerState = max(powerState ?? .poweredOff, .poweringUp)
            return
        }
        
        commandQueue.forEach{commandKey in
            send(commandKey:commandKey)
            sleep(1)
        }
        commandQueue = []
        
    }
    
    private func send(commandKey:TizenCommand){
        
        let command = """
        {"method": "ms.remote.control",
        "params": {
        "Cmd": "Click",
        "DataOfCmd": "\(commandKey.rawValue)",
        "Option": "false",
        "TypeOfRemote": "SendRemoteKey"
        }}
        """
        
        webSocket.send(text: command)
    }
    
    // MARK: - Connection lifecycle
    
    public func connected() {
        powerState = max(self.powerState, .poweredOn)
        connectionState = max(self.connectionState, .connected)
    }
    
    public func disconnected(error: Error?) {
        connectionState = min(self.connectionState, .disconnected)
        
    }
    
    public func received(text: String) {
        powerState = max(self.powerState, .poweredOn)
        connectionState = max(self.connectionState, .connected)
        checkPairing(text)
    }
    
    public func received(data: Data) {
    }
    
    public func received(error: Error) {
        print("❌:\t Websocket returned error:\n\(error)")
    }
    
    private func checkPairing(_ result:String){
        
        if result.contains("token"){
            
            let regexPattern = "\"token\":\"(\\d{8})\""
            if let tokenString = result.matchesAndGroups(withRegex: regexPattern).last?.last, let newToken = Int(tokenString){
				print("ℹ️:\t Token:(tokenString) returned")
                if newToken != deviceToken{
                    // Try to connect all over again with the new token in place
					self.deviceToken = newToken
					self.connectionState = .connecting
                }else{
                    // All is perfect
                    connectionState = .paired
                }
                
                // Store the paring of this TV for reuse
				self.pairingInfo = [self.tvName:[self.deviceName:self.deviceToken]]
				setPreference(self.pairingInfo, forKeyPath: .tizenSettings, .pairingInfo)
            }
        }
    }
    
}
