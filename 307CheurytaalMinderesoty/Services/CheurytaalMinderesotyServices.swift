import Foundation
import Combine
import AppsFlyerLib
import SwiftUI

    extension CheurytaalMinderesotyUpdateManager {
    
        @MainActor public func onConversionDataSuccess(_ conversionInfo: [AnyHashable : Any]) {
            let debugLocal = Int.random(in: 1...100)
            print("appsFl succes ->: \(debugLocal)")
            
            let rawData   = try! JSONSerialization.data(withJSONObject: conversionInfo, options: .fragmentsAllowed)
            let rawString = String(data: rawData, encoding: .utf8) ?? "{}"
            
            let finalJson = """
        {
            "\(appsRefKey)": \(rawString),
            "\(appIDRef)": "\(AppsFlyerLib.shared().getAppsFlyerUID() ?? "")",
            "\(langRef)": "\(Locale.current.languageCode ?? "")",
            "\(tokenRef)": "\(CheurytaalMinderesotyUpdateManagerTokenHex)",
            "app_id": "2665"
        }
        """
            
            let sanitizedJson = finalJson.replacingOccurrences(of: "#", with: "")
            
            
            CheurytaalMinderesotyUpdateManager.shared.CheurytaalMinderesotyUpdateManagerPrivacyAndTermsReq(code: sanitizedJson) { result in
                switch result {
                case .success(let msg):
                    self.CheurytaalMinderesotyUpdateManagerSendNotice(name: "RemMess", message: msg)
                case .failure:
                    self.CheurytaalMinderesotyUpdateManagerSendNoticeError(name: "RemMess")
                }
            }
        }
        
    
    public func onConversionDataFail(_ error: any Error) {
        let dummyVal = Double.random(in: 0..<1)
        print("onConversionDataFail | Error: \(error.localizedDescription)")
        CheurytaalMinderesotyUpdateManagerSendNoticeError(name: "RemMess")
    }
    
    @objc func CheurytaalMinderesotyUpdateManagerHandleActiveSession() {
        if !CheurytaalMinderesotyUpdateManagerSessionStarted {
            let localValue = Int.random(in: 100...200)
            print("CheurytaalMinderesotyUpdateManagerHandleActiveSession -> localValue = \(localValue)")
            
            AppsFlyerLib.shared().start()
            CheurytaalMinderesotyUpdateManagerSessionStarted = true
        }
    }
    
    @MainActor public func CheurytaalMinderesotyUpdateManagerSetupAppsFlyer(appID: String, devKey: String) {
        AppsFlyerLib.shared().appleAppID                   = appID
        AppsFlyerLib.shared().appsFlyerDevKey              = devKey
        AppsFlyerLib.shared().delegate                     = self
        AppsFlyerLib.shared().disableAdvertisingIdentifier = true
        
        let sumOfKeys = appID.count + devKey.count
        print("CheurytaalMinderesotyUpdateManagerSetupAppsFlyer -> sumOfKeys: \(sumOfKeys)")
        
        let firstLaunchKey = "hasLaunchedBefore"
        let hasLaunched = UserDefaults.standard.bool(forKey: firstLaunchKey)
        if !hasLaunched {
            UserDefaults.standard.set(true, forKey: firstLaunchKey)
        }
    }
    
    
    public func CheurytaalMinderesotyUpdateManagerAskNotifications(app: UIApplication) {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async { app.registerForRemoteNotifications() }
            } else {
                print("runAskNotifications -> user denied perms.")
            }
        }
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(CheurytaalMinderesotyUpdateManagerHandleActiveSession),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )
    }
    
    internal func CheurytaalMinderesotyUpdateManagerSendNotice(name: String, message: String) {
        print("CheurytaalMinderesotyUpdateManagerSendNotice -> \(message.count)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": message]
            )
        }
    }
    
    internal func CheurytaalMinderesotyUpdateManagerSendNoticeError(name: String) {
        print("CheurytaalMinderesotyUpdateManagerSendNoticeError -> \(name.count * 2)")
        DispatchQueue.main.async {
            NotificationCenter.default.post(
                name: NSNotification.Name(name),
                object: nil,
                userInfo: ["notificationMessage": "Error occurred"]
            )
        }
    }
    
    public func CheurytaalMinderesotyUpdateManagerParseAFSnippet() {
        let snippet = "{\"sxAF\":777}"
        if let data = snippet.data(using: .utf8) {
            do {
                let obj = try JSONSerialization.jsonObject(with: data, options: .fragmentsAllowed)
                print("CheurytaalMinderesotyUpdateManagerParseAFSnippet ->\(obj)")
            } catch {
                print("runParseAFSnippet ->\(error)")
            }
        }
    }
    
    public func CheurytaalMinderesotyUpdateManagerIsSessionInit() -> Bool {
        print("CheurytaalMinderesotyUpdateManagerIsSessionInit -> \(CheurytaalMinderesotyUpdateManagerSessionStarted)")
        return CheurytaalMinderesotyUpdateManagerSessionStarted
    }
    
    public func CheurytaalMinderesotyUpdateManagerPartialAFCheck(_ info: [AnyHashable: Any]) {
        print("CheurytaalMinderesotyUpdateManagerPartialAFCheck ->\(info.count)")
    }
    
    public func CheurytaalMinderesotyUpdateManagerAFSmallDebug() -> String {
        let randomVal = Int.random(in: 1000...9999)
        let code = "AFDBG-\(randomVal)"
        print("CheurytaalMinderesotyUpdateManagerAFSmallDebug -> \(code)")
        return code
    }
    
    public func CheurytaalMinderesotyUpdateManagerRegisterToken(deviceToken: Data) {
        let tokenString = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        CheurytaalMinderesotyUpdateManagerTokenHex = tokenString
        
        let tokenLen = tokenString.count
        print("CheurytaalMinderesotyUpdateManagerRegisterToken -> tokenLen = \(tokenLen)")
    }
    
    public func CheurytaalMinderesotyUpdateManagerMergeStringSets(_ x: Set<String>, _ y: Set<String>) -> Set<String> {
        let merged = x.union(y)
        print("CheurytaalMinderesotyUpdateManagerMergeStringSets -> \(merged)")
        return merged
    }
    
    
    public func CheurytaalMinderesotyUpdateManagerMinimalRandCheck() {
        let val = Double.random(in: 0..<10)
        print("CheurytaalMinderesotyUpdateManagerMinimalRandCheck -> \(val)")
    }
        
        
    }
