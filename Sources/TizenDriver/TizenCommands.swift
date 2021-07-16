//
//  TizenCommands.swift
//  
//
//  Created by Jan Verrept on 28/02/2020.
//

public enum TizenCommand:String {
	
    case KEY_POWER
    
    case KEY_UP
    case KEY_DOWN
    case KEY_LEFT
    case KEY_RIGHT
    case KEY_CHUP
    case KEY_CHDOWN
	case KEY_PRECH
    case KEY_ENTER
    case KEY_RETURN
    case KEY_EXIT
    case KEY_CONTENTS
    case KEY_CH_LIST
    case KEY_MENU
    case KEY_SOURCE
    case KEY_GUIDE
    case KEY_TOOLS
    case KEY_INFO
    case KEY_RED
    case KEY_GREEN
    case KEY_YELLOW
    case KEY_BLUE
    case KEY_PANNEL_CHDOWN
    case KEY_VOLUP
    case KEY_VOLDOWN
    case KEY_MUTE
    case KEY_0
    case KEY_1
    case KEY_2
    case KEY_3
    case KEY_4
    case KEY_5
    case KEY_6
    case KEY_7
    case KEY_8
    case KEY_9
    case KEY_DTV
    case KEY_HDMI
    case KEY_DTV_LINK
    case KEY_EXT5
	case KEY_EMANUAL
	case KEY_SEARCH
	case KEY_CAPTION
}

public enum TizenApp:Int {
	case All4 = 111299002148
	case AppleTV = 3201807016597
	case BBCnews = 3201602007865
	case BBCsport = 3201602007866
	case BBCiPlayer = 3201601007670
	case BTsport = 3201811017267
	case CHILI = 3201505002690
	case DisneyPlus = 3201901017640
	case FacebookWatch = 11091000000
	case Gallery = 3201710015037
	case GooglePlayMovies = 3201601007250
	case HBOgo = 3201706012478
	case ITVhub = 121299000089
//	case Internet = org.tizen.browser
	case McAfeeSecurityForTV = 3201612011418
	case My5 = 121299000612
	case NOWTV = 3201603008746
	case Netflix = 11101200001
	case PrimeVideo = 3201512006785
	case RakutenTV = 3201511006428
//	case Samagic = vWMh8q6Ce0.Samagic
	case SmartThings = 3201710015016
	case Spotify = 3201606009684
	case SteamLink = 3201702011851
	case UniversalGuide = 3201710015067
	case YouTube = 111299001912
	case hayu = 3201806016381
}



//LIst of installed Apps
//{"method":"ms.channel.emit","params":{"event": "ed.installedApp.get", "to":"host"}}

// Launch an App (example = Netflix)
//{
//"method": "ms.channel.emit",
//"params": {
//		"event": "ed.apps.launch",
//		"to": "host",
//		"data": {
//			"appId": "11101200001",
//			"action_type": "DEEP_LINK"
//			}
//	}
//}
//}

// Launch browser
//{"method":"ms.channel.emit","params":{"event": "ed.apps.launch", "to":"host", "data":{"appId": "org.tizen.browser", "action_type": "NATIVE_LAUNCH"}}}

// Launch browser with url
//{"method":"ms.channel.emit","params":{"event": "ed.apps.launch", "to":"host", "data":{"appId":"org.tizen.browser","action_type":"NATIVE_LAUNCH","metaTag":"http:\/\/hackaday.com"}}}

// Get HTTP info
// http://192.168.0.50:8001/api/v2/applications/11101200001
