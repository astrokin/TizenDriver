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
		
		case deviceTokens
				
	}
		
	public var preferences:[String:[String:Int]]{
		
		var preferences:[String:[String:Int]] = [:]
		
		preferences["DeviceTokens"] = getPreference(forKey: .tizenSettings, secondaryKey: .deviceTokens)
		
		return preferences
	}
	
}
