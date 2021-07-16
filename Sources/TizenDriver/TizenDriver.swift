import Foundation
import Awake
import JVCocoa

open class TizenDriver:WebSocketDelegate{
	
	// MARK: - Setup
	public let tvName:String
	let macAddress:String
	let ipAddress:String
	let port:Int
	let deviceName:String
	var pairingInfo:[String:[String:Int]] = [:]
	var deviceToken:Int!
	
	private var powerStateTimer:Timer!
	private let powerStatePinger:Pinger = Pinger()
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
	
	open var powerState:PowerState = .poweredOff{
		
		// Prepare for .poweredOn or .poweredOff
		willSet{
			
			switch newValue {
					
				case .poweringUp:
					
					// When reachable
					if (powerState != .poweredOn){
						// Perform a WakeOnLan to turn the TV on
						let tv = Awake.Device(MAC: macAddress, BroadcastAddr: "255.255.255.255", Port: 9)
						_ = Awake.target(device: tv)
					}else{
						queue(commands: [.KEY_POWER])
					}
					
				case .poweringDown:
					
					if (powerState != .poweredOff) {
						// Send KEY_POWER to the TV turn off
						queue(commands: [.KEY_POWER])
					}
					
				default:
					break
			}
		}
		
		didSet{
			
			if powerState == .undefined{
				powerState = physicalPowerState
			}
		}
		
	}
	private var physicalPowerState:PowerState{
		
		get{
			let fysicalPowerState = self.powerStatePinger.ping(ipAddress, timeOut: 1.0, maxResponsTime: 1.0)
			if fysicalPowerState == true{
				print("🔲:\t '\(tvName)' powered on")
				if let connectionState =  self.connectionState, connectionState <= .connected{
					self.connectionState = .connecting
				}
				return .poweredOn
			}else{
				print("🔳:\t '\(tvName)' powered off")
				connectionState = .disconnected
				return .poweredOff
			}
		}
		
	}
	
	private var webSocket:WebSocket{
		let base64DeviceName = Data(deviceName.utf8).base64EncodedString()
		let connectionString = "wss://\(ipAddress):\(port)/api/v2/channels/samsung.remote.control?name=\(base64DeviceName)&token=\(deviceToken ?? 0)"
		print("Connectionstring:\n\(connectionString)")
		var urlRequest =  URLRequest(url: URL(string: connectionString)!)
		urlRequest.timeoutInterval = 5
		let webSocket = WebSocket(urlRequest: urlRequest, delegate: self)
		return webSocket
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
		
		// Prepare for .connected or .disconnected
		willSet{
			
			switch newValue {
					
				case .disconnecting:
					
					webSocket.disconnect()
					
				case .connecting:
					
					webSocket.connect()
					
				default:
					break
					
			}
			
		}
		
		didSet{
			
			if connectionState != oldValue{
				
				switch connectionState {
						
					case .paired:
						
						if let token = self.deviceToken{
							print("✅:\t \(deviceName) paired with '\(tvName)' using key \(token)")
						}
						// SEND QUEUED COMMANDS ONCE PAIRING SUCCEEDED!!
						if !commandQueue.isEmpty{
							queue()
						}else{
							webSocket.ping()
						}
						
					default:
						break
						
				}
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
		
		self.powerStateTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
			if self.powerState != .undefined{
				self.powerState = .undefined
			}
		}
		
		self.pairingInfo = getPreference(forKeyPath: .tizenSettings, .pairingInfo) ?? [:]
		self.deviceToken = self.pairingInfo[tvName]?[deviceName]
		if let token = self.deviceToken{
			print("ℹ️ \t Token:\(token) from prefs for \(tvName)")
		}
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
	
	public func openApp(_ app:TizenApp){
		//		if let keyCommand = TizenCommand(rawValue:"KEY_\(channelNumber)"){
		//			queue(commands:[keyCommand, .KEY_ENTER] )
		//		}
	}
	
	
	public func queue(commands commandKeys:[TizenCommand]? = nil){
		
		if let newCommands = commandKeys{
			commandQueue += newCommands
		}
		
		guard (powerState == .poweredOn) else{
			powerState = .poweringUp
			return
		}
		
		guard (connectionState == .paired) else{
			connectionState = .connecting
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
		print("🔗:\t \(deviceName) connected with '\(tvName)'")
		connectionState = .connected
	}
	
	public func disconnected(error: Error?) {
		print(":\t \(deviceName) disconnected from '\(tvName)'")
		connectionState = .disconnected
	}
	
	public func received(text: String) {
		checkPairing(text)
	}
	
	public func received(data: Data) {
		// Not used the communication is text based
	}
	
	public func received(error: Error) {
		print("❌:\t Websocket returned error:\n\(error)")
		connectionState = .disconnected
	}
	
	private func checkPairing(_ result:String){
		
		if result.contains("token"){
			
			let regexPattern = "\"token\":\"(\\d{8})\""
			if let tokenString = result.matchesAndGroups(withRegex: regexPattern).last?.last, let newToken = Int(tokenString){
				print("ℹ️:\t Token:\(tokenString) returned")
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

