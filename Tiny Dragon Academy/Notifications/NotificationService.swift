//
//  NotificationService.swift
//  Tiny Dragon Academy
//
//  Thin wrapper over UNUserNotificationCenter: replaces all pending care
//  reminders with the latest plan and routes taps back into the app.
//

import Foundation
import UserNotifications

@MainActor
protocol NotificationScheduling: AnyObject {
    func schedule(_ plan: [PlannedNotification])
    func requestAuthorization() async -> Bool
    func authorizationDenied() async -> Bool
}

@MainActor
final class NotificationService: NSObject, NotificationScheduling {
    static let shared = NotificationService()

    /// Called with the tapped notification's dragon id.
    var onTap: ((String) -> Void)?

    private let center = UNUserNotificationCenter.current()

    private override init() {
        super.init()
        center.delegate = self
    }

    func schedule(_ plan: [PlannedNotification]) {
        center.removeAllPendingNotificationRequests()
        let calendar = Calendar.current
        for item in plan where item.fireDate > Date() {
            let content = UNMutableNotificationContent()
            content.title = item.title
            content.body = item.body
            content.sound = .default
            if let dragonId = item.dragonId {
                content.userInfo = ["dragonId": dragonId]
            }
            let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: item.fireDate)
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            center.add(UNNotificationRequest(identifier: item.id, content: content, trigger: trigger))
        }
    }

    func requestAuthorization() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    func authorizationDenied() async -> Bool {
        await center.notificationSettings().authorizationStatus == .denied
    }
}

extension NotificationService: UNUserNotificationCenterDelegate {
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        [.banner, .sound]
    }

    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter,
                                            didReceive response: UNNotificationResponse) async {
        guard let dragonId = response.notification.request.content.userInfo["dragonId"] as? String else { return }
        await MainActor.run { NotificationService.shared.onTap?(dragonId) }
    }
}
