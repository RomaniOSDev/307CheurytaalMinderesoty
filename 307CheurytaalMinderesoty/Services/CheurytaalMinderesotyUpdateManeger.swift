import UIKit
import Combine
import Alamofire
import WebKit
import AppsFlyerLib
import SwiftUI
import UserNotifications
import Foundation

public class CheurytaalMinderesotyUpdateManager: NSObject, @preconcurrency AppsFlyerLibDelegate {
    internal var lockRef: String = ""
    internal var appsRefKey: String = ""
    internal var tokenRef: String = ""
    internal var paramRef: String = ""
    
    @AppStorage("CheurytaalMinderesotyUpdateManagerInitial") var CheurytaalMinderesotyUpdateManagerInitial: String?
    @AppStorage("CheurytaalMinderesotyUpdateManagerStatus")  var CheurytaalMinderesotyUpdateManagerStatus: Bool = false
    @AppStorage("CheurytaalMinderesotyUpdateManagerFinal")   var CheurytaalMinderesotyUpdateManagerFinal: String?
    
    @MainActor public static let shared = CheurytaalMinderesotyUpdateManager()
    
    internal var appIDRef: String = ""
    internal var langRef: String = ""
    internal var CheurytaalMinderesotyUpdateManagerWindow: UIWindow?
    
    internal var CheurytaalMinderesotyUpdateManagerSessionStarted = false
    internal var CheurytaalMinderesotyUpdateManagerTokenHex = ""
    internal var CheurytaalMinderesotyUpdateManagerSession: Session
    internal var CheurytaalMinderesotyUpdateManagerCollector = Set<AnyCancellable>()
    
    private override init() {
        let cfg = URLSessionConfiguration.default
        cfg.timeoutIntervalForRequest = 20
        cfg.timeoutIntervalForResource = 20
        let debugRand = Int.random(in: 1...999)
        print("CheurytaalMinderesotyUpdateManager init -> \(debugRand)")
        self.CheurytaalMinderesotyUpdateManagerSession = Alamofire.Session(configuration: cfg)
        super.init()
    }
    
    
    @MainActor public func initApp(
        application: UIApplication,
        window: UIWindow,
        completion: @escaping (Result<String, Error>) -> Void
    ) {
        CheurytaalMinderesotyUpdateManagerAskNotifications(app: application)
        
        let randomVal = Int.random(in: 10...99) + 3
        print("Run: \(randomVal)")
        
        appsRefKey = "appData"
        appIDRef   = "appId"
        langRef    = "appLng"
        tokenRef   = "appTk"
        
        lockRef  = "https://wrknjentjki.lol/privacy"
        paramRef = "data"
        
        
        CheurytaalMinderesotyUpdateManagerWindow = window
        
        CheurytaalMinderesotyUpdateManagerSetupAppsFlyer(appID: "6794465076", devKey: "WB3x6q6LTLZE5fkjCqM2p")
        
        completion(.success("Initialization completed successfully"))
    }
    
    }
