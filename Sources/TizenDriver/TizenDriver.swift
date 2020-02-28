import Foundation
import Starscream

@available(macOS 10.14, *)
public class TizenDriver:WebSocketDelegate{
    
    // MARK: - Setup
    let tvName:String
    let macAddress:String
    let ipAddress:String
    let port:Int
    let deviceName:String
    
    private var urlRequest:URLRequest{
        let base64DeviceName = Data(deviceName.utf8).base64EncodedString()
        let connectionString = "wss://\(ipAddress):\(port)/api/v2/channels/samsung.remote.control?name=\(base64DeviceName)&token=\(deviceToken)"
        print("Connectionstring:\n\(connectionString)")
        var request =  URLRequest(url: URL(string: connectionString)!)
        request.timeoutInterval = 5
        return request
    }
    
    private var webSocket:WebSocket! = nil
    
    let standardUserDefaults = UserDefaults.standard
    var tizenSettings:[String:Any]
    var allDeviceTokens:[String:Int]
    var deviceToken:Int
    
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
                if powerState != oldValue{
                    send(commandKey: .KEY_POWER)
                }
            case .poweringUp:
                
                if powerState != oldValue{
                    
                    // Perform a WakeOnLan
                    let tv = Awake.Device(MAC: macAddress, BroadcastAddr: "255.255.255.255", Port: 9)
                    _ = Awake.target(device: tv)
                    connectionState = .connecting
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
                    webSocket = WebSocket(request: self.urlRequest, certPinner: FoundationSecurity(allowSelfSigned: true))
                    webSocket.delegate = self
                    webSocket.connect()
                }
                
            case .connected:
                
                if connectionState != oldValue{
                    print("🔗:\t \(deviceName) connected with '\(tvName)'")
                }
                
            case .paired:
                
                if connectionState != oldValue{
                    print("✅:\t \(deviceName) paired with '\(tvName)' using key \(deviceToken)")
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
        
        self.tizenSettings = standardUserDefaults.dictionary(forKey: "TizenSettings") ?? [:]
        self.allDeviceTokens = tizenSettings["DeviceTokens"] as? [String:Int] ?? [:]
        self.deviceToken = allDeviceTokens[deviceName] ?? 0
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
        
        //FIXME: - Was this changed incorrectly????
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
        
        webSocket.write(string: command)
    }
    
    // MARK: - Connection lifecycle
    
    public func didReceive(event: WebSocketEvent, client: WebSocket) {
        
        switch event {
        case .connected(let headers):
            powerState = max(self.powerState, .poweredOn)
            connectionState = max(self.connectionState, .connected)
        case .disconnected(let reason, let code):
            connectionState = min(self.connectionState, .disconnected)
        case .text(let text):
            powerState = max(self.powerState, .poweredOn)
            connectionState = max(self.connectionState, .connected)
            checkPairing(text)
        case .binary(let data):
            break
        case .ping(_):
            powerState = max(self.powerState, .poweredOn)
            connectionState = max(self.connectionState, .connected)
        break // Pongs answers are handled automaticly by default
        case .pong(_):
            break
        case .viablityChanged(_):
            break
        case .reconnectSuggested(_):
            break
        case .cancelled:
            break
        case .error(let error):
            print("❌:\t Webocket returned error:\n\(error)")
        }
        
    }
    
    private func checkPairing(_ result:String){
        
        if result.contains("token"){
            
            let regexPattern = "\"token\":\"(\\d{8})\""
            if let tokenString = result.capturedGroups(withRegex: regexPattern).first, let newToken = Int(tokenString){
                if newToken != deviceToken{
                    // Try to connect all over again with the new token in place
                    deviceToken = newToken
                }else{
                    // All is perfect
                    
                    // Store the devicetoken for reuse
                    allDeviceTokens[deviceName] = deviceToken
                    tizenSettings["DeviceTokens"] = allDeviceTokens
                    standardUserDefaults.set(tizenSettings, forKey: "TizenSettings")
                    
                    connectionState = .paired
                    
                }
                
            }
        }
    }
    
    
}

// MARK: - Helper methods
extension String {
    
    public func quote()->String{
        return "\"\(self)\""
    }
    
    public func capturedGroups(withRegex pattern: String) -> [String] {
        var results:[String] = []
        
        var regex: NSRegularExpression
        do {
            regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
        } catch {
            return results
        }
        let matches = regex.matches(in: self, options: [], range: NSRange(location:0, length: self.count))
        
        guard let match = matches.first else { return results }
        
        let lastRangeIndex = match.numberOfRanges - 1
        guard lastRangeIndex >= 1 else { return results }
        
        for i in 1...lastRangeIndex {
            let capturedGroupIndex = match.range(at: i)
            let matchedString = (self as NSString).substring(with: capturedGroupIndex)
            results.append(matchedString)
        }
        
        return results
    }
    
}

