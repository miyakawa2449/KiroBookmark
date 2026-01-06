//
//  NotificationService.swift
//  KiroBookmark
//
//  Service for managing local notifications
//

import Foundation
import UserNotifications

// MARK: - NotificationServiceProtocol

protocol NotificationServiceProtocol {
    func requestAuthorization() async -> Bool
    func checkAuthorizationStatus() async -> UNAuthorizationStatus
    func scheduleNewArticleNotification(count: Int, blogName: String)
    func updateBadgeCount(_ count: Int) async
    func clearAllNotifications()
    func clearBadge() async
}

// MARK: - NotificationService

final class NotificationService: NotificationServiceProtocol {

    private let notificationCenter: UNUserNotificationCenter
    private let userDefaults: UserDefaults

    // MARK: - Keys

    private enum Keys {
        static let notificationEnabled = "notification.enabled"
        static let badgeEnabled = "notification.badgeEnabled"
        static let soundEnabled = "notification.soundEnabled"
    }

    // MARK: - Initialization

    init(
        notificationCenter: UNUserNotificationCenter = .current(),
        userDefaults: UserDefaults = .standard
    ) {
        self.notificationCenter = notificationCenter
        self.userDefaults = userDefaults
    }

    // MARK: - Authorization

    func requestAuthorization() async -> Bool {
        do {
            let options: UNAuthorizationOptions = [.alert, .badge, .sound]
            return try await notificationCenter.requestAuthorization(options: options)
        } catch {
            print("Notification authorization error: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await notificationCenter.notificationSettings()
        return settings.authorizationStatus
    }

    // MARK: - Schedule Notifications

    func scheduleNewArticleNotification(count: Int, blogName: String) {
        guard isNotificationEnabled else { return }
        guard count > 0 else { return }

        let content = UNMutableNotificationContent()
        content.title = "新着記事"
        content.body = "\(blogName)から\(count)件の新しい記事があります"

        if isSoundEnabled {
            content.sound = .default
        }

        if isBadgeEnabled {
            content.badge = NSNumber(value: count)
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )

        notificationCenter.add(request) { error in
            if let error = error {
                print("Notification scheduling error: \(error)")
            }
        }
    }

    // MARK: - Badge Management

    func updateBadgeCount(_ count: Int) async {
        guard isBadgeEnabled else { return }

        let content = UNMutableNotificationContent()
        content.badge = NSNumber(value: count)

        let request = UNNotificationRequest(
            identifier: "badge-update",
            content: content,
            trigger: nil
        )

        do {
            try await notificationCenter.add(request)
        } catch {
            print("Badge update error: \(error)")
        }
    }

    func clearBadge() async {
        await updateBadgeCount(0)
    }

    // MARK: - Clear Notifications

    func clearAllNotifications() {
        notificationCenter.removeAllDeliveredNotifications()
        notificationCenter.removeAllPendingNotificationRequests()
    }

    // MARK: - Settings Helpers

    var isNotificationEnabled: Bool {
        userDefaults.bool(forKey: Keys.notificationEnabled)
    }

    var isBadgeEnabled: Bool {
        userDefaults.bool(forKey: Keys.badgeEnabled)
    }

    var isSoundEnabled: Bool {
        userDefaults.bool(forKey: Keys.soundEnabled)
    }
}
