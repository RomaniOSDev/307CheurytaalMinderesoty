import Foundation
import UserNotifications

final class NotificationService: NSObject {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()
    private var didRequestAuth = false

    private override init() {
        super.init()
    }

    func configure() {
        center.delegate = self
    }

    func requestAuthorizationIfNeeded() {
        guard !didRequestAuth else { return }
        didRequestAuth = true
        center.requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }

    func scheduleTimerFinished(id: UUID, dishName: String, afterSeconds: Int) {
        guard afterSeconds > 0 else { return }
        requestAuthorizationIfNeeded()
        cancelTimerNotification(id: id)

        let content = UNMutableNotificationContent()
        content.title = "Timer Done"
        content.body = "\(dishName) is ready."
        if HapticService.soundEnabled {
            content.sound = .default
        }

        let trigger = UNTimeIntervalNotificationTrigger(
            timeInterval: TimeInterval(afterSeconds),
            repeats: false
        )
        let request = UNNotificationRequest(
            identifier: notificationId(for: id),
            content: content,
            trigger: trigger
        )
        center.add(request)
    }

    func cancelTimerNotification(id: UUID) {
        center.removePendingNotificationRequests(withIdentifiers: [notificationId(for: id)])
        center.removeDeliveredNotifications(withIdentifiers: [notificationId(for: id)])
    }

    func cancelAllTimerNotifications() {
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    private func notificationId(for id: UUID) -> String {
        "cook_timer_\(id.uuidString)"
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        if HapticService.soundEnabled {
            completionHandler([.banner, .sound])
        } else {
            completionHandler([.banner])
        }
    }
}
