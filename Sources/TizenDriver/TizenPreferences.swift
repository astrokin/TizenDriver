//
//  TizenPreferences.swift
//  
//
//  Created by Jan Verrept on 06/04/2021.
//

import JVCocoa

extension TizenDriver:PreferenceBased {
	
	public enum PreferenceKey:String, StringRepresentableEnum{
		
		case tizenSettings
		
		case pairingInfo
				
	}
		
	public var preferences:[String:[String:Int]]{
		
		var preferences:[String:[String:Int]] = [:]
		
		preferences["pairingInfo"] = getPreference(forKeyPath: .tizenSettings, .pairingInfo)
		
		return preferences
	}
	
}
