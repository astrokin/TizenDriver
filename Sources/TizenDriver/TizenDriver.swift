import Foundation
import JVCocoa
import SwiftyPing

public class TizenDriver:WebSocketDelegate{
	
	// MARK: - Setup
	let tvName:String
	let macAddress:String
	let ipAddress:String
	let port:Int
	let deviceName:String
	let pinger:Pinger = Pinger()
	
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
	
	public var powerState:PowerState!{
		
		get{
			
			// Check ping-repons to detect de TV's actual power-state
			let actualPowerState = self.pinger.ping(ipAddress, maxResponsTime: 1)
			if actualPowerState == true{
				print("🔲:\t '\(tvName)' powered on")
				return .poweredOn
			}else{
				print("🔳:\t '\(tvName)' powered off")
				return .poweredOff
			}
		}
		
		set{
			
				switch newValue {
					
					case .poweringUp:
						
						if (powerState < .poweringUp){
							// Perform a WakeOnLan to turn the TV on
							let tv = Awake.Device(MAC: macAddress, BroadcastAddr: "255.255.255.255", Port: 9)
							_ = Awake.target(device: tv)
						}else{
							queue(commands: [.KEY_POWER])
						}
						
					case .poweringDown:
						
						if (powerState > .poweringDown) {
							// Send KEY_POWER to the TV turn off
							queue(commands: [.KEY_POWER])
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
			
			if connectionState != oldValue{
				
				switch connectionState {
					
					case .disconnected:
						
						print(":\t \(deviceName) disconnected from '\(tvName)'")
						
					case .disconnecting:
						
						webSocket.disconnect()
						
					case .connecting:
						
						webSocket = WebSocket(urlRequest: urlRequest, delegate: self)
						webSocket.connect()
						
					case .connected:
						
						print("🔗:\t \(deviceName) connected with '\(tvName)'")
						
					case .paired:
						
						if let token = self.deviceToken{
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
		if let token = self.deviceToken{
			print("ℹ️ \t Token:\(token) from prefs for \(tvName)")
		}
		
	}
	
	deinit {
		// perform the deinitialization
		powerState = .poweringDown
		connectionState = .disconnecting
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
		if let webSocket =  self.webSocket{
			webSocket.send(text: command)
		}
	}
	
	// MARK: - Connection lifecycle
	
	public func connected() {
		connectionState = .connected
	}
	
	public func disconnected(error: Error?) {
		connectionState = .disconnected
	}
	
	public func received(text: String) {
		connectionState = .connected
		checkPairing(text)
	}
	
	public func received(data: Data) {
		// Not used the communication is text based
	}
	
	public func received(error: Error) {
		print("❌:\t Websocket returned error:\n\(error)")
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
