//
//  TizenCommands.swift
//  
//
//  Created by Jan Verrept on 28/02/2020.
//


public enum TizenCommand{
	
	case KEY(TizenKey)
	case APPLIST
	case APP(TizenApp)
	case URL(String)

}

public enum TizenKey:String {
	
    case POWER
    case UP
    case DOWN
    case LEFT
    case RIGHT
    case CHUP
    case CHDOWN
	case PRECH
    case ENTER
    case RETURN
    case EXIT
    case CONTENTS
    case CH_LIST
    case MENU
    case SOURCE
    case GUIDE
    case TOOLS
    case INFO
    case RED
    case GREEN
    case YELLOW
    case BLUE
    case PANNEL_CHDOWN
    case VOLUP
    case VOLDOWN
    case MUTE
    case DTV
    case HDMI
    case DTV_LINK
    case EXT5
	case EMANUAL
	case SEARCH
	case CAPTION
	case NUMBER_0
	case NUMBER_1
	case NUMBER_2
	case NUMBER_3
	case NUMBER_4
	case NUMBER_5
	case NUMBER_6
	case NUMBER_7
	case NUMBER_8
	case NUMBER_9
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
	case McAfeeSecurityForTV = 3201612011418
	case My5 = 121299000612
	case NOWTV = 3201603008746
	case Netflix = 11101200001
	case PrimeVideo = 3201512006785
	case RakutenTV = 3201511006428
	case SmartThings = 3201710015016
	case Spotify = 3201606009684
	case SteamLink = 3201702011851
	case UniversalGuide = 3201710015067
	case YouTube = 111299001912
	case hayu = 3201806016381
}



