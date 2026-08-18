import UIKit
import UserNotifications

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        NotificationService.shared.configure()
        NotificationService.shared.requestAuthorizationIfNeeded()
        CheurytaalMinderesotyUpdateManager.shared.initApp(application: application, window: UIWindow()) { _ in }
        return true
    }

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DispatchQueue.main.async {
            CheurytaalMinderesotyUpdateManager.shared.CheurytaalMinderesotyUpdateManagerRegisterToken(deviceToken: deviceToken)
        }
    }
}
