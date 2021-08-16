// This file was generated from JSON Schema using quicktype, do not modify it directly.
// To parse the JSON, add this file to your project and do:
//
//   let tizenAppsRootData = try? newJSONDecoder().decode(TizenAppsRootData.self, from: jsonData)

import Foundation

// MARK: - TizenAppsRootData
struct TizenAppsRootData: Decodable {
	let data: DataContainer
	let event: String
	let from: String

	enum CodingKeys: String, CodingKey {
		case data
		case event
		case from
	}
}

// MARK: - DataContainer
struct DataContainer: Decodable{
	let data: [TizenAppInfo]

	enum CodingKeys: String, CodingKey {
		case data = "data"
	}
}

extension TizenApp:Decodable{}

enum TizenAppType:Int, Decodable{
	case DEEP_LINK = 2
	case NATIVE_LAUNCH = 4
}

// MARK: - TizenAppInfo
struct TizenAppInfo: Decodable {
	
	let name: String
	let id: TizenApp
	let type: TizenAppType
	let icon: String
	let isLock: Int

	enum CodingKeys: String, CodingKey {
		case name
		case id = "appId"
		case type = "app_type"
		case icon
		case isLock = "is_lock"
	}
}
