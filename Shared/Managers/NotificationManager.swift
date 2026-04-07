import Combine
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    private let center: UNUserNotificationCenter
    private let userDefaults: UserDefaults
    private let reminderEnabledKey = "reminderEnabled"
    private let reminderSettingsPrefix = "reminderSettings-"
    private let calendar: Calendar

    init(
        center: UNUserNotificationCenter = .current(),
        userDefaults: UserDefaults = .standard,
        calendar: Calendar = .current
    ) {
        self.center = center
        self.userDefaults = userDefaults
        self.calendar = calendar
    }

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleNotification(for subscription: Subscription, daysBefore: Int, hour: Int, minute: Int) async {
        let identifier = reminderIdentifier(for: subscription, daysBefore: daysBefore)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard let scheduledDate = scheduledDate(
            for: subscription,
            daysBefore: daysBefore,
            hour: hour,
            minute: minute
        ) else {
            return
        }

        let request = NotificationReminderRequestFactory.makeRequest(
            identifier: identifier,
            title: reminderTitle(for: subscription, daysBefore: daysBefore),
            body: reminderBody(for: subscription),
            scheduledDate: scheduledDate,
            calendar: calendar
        )

        try? await center.add(request)
    }

    func cancelReminder(for subscription: Subscription) async {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers(for: subscription))
    }

    func reminderSettings(for subscription: Subscription) -> ReminderSettings? {
        NotificationReminderSettingsStore.loadSettings(
            userDefaults: userDefaults,
            key: reminderSettingsKey(for: subscription)
        )
    }

    func saveReminderSettings(for subscription: Subscription, hour: Int, minute: Int, daysBefore: Int) {
        let settings = ReminderSettings(hour: hour, minute: minute, daysBefore: daysBefore)
        NotificationReminderSettingsStore.saveSettings(
            settings,
            userDefaults: userDefaults,
            key: reminderSettingsKey(for: subscription),
            reminderEnabledKey: reminderEnabledKey,
            reminderSettingsPrefix: reminderSettingsPrefix
        )
    }

    func removeReminderSettings(for subscription: Subscription) {
        NotificationReminderSettingsStore.removeSettings(
            userDefaults: userDefaults,
            key: reminderSettingsKey(for: subscription),
            reminderEnabledKey: reminderEnabledKey,
            reminderSettingsPrefix: reminderSettingsPrefix
        )
    }

    func rescheduleAllReminders(services: [Service]) async {
        center.removeAllPendingNotificationRequests()

        for service in services {
            for subscription in service.subscriptions where subscription.isActive {
                guard let settings = reminderSettings(for: subscription) else { continue }
                await scheduleNotification(
                    for: subscription,
                    daysBefore: 0,
                    hour: settings.hour,
                    minute: settings.minute
                )
                if settings.daysBefore > 0 {
                    await scheduleNotification(
                        for: subscription,
                        daysBefore: settings.daysBefore,
                        hour: settings.hour,
                        minute: settings.minute
                    )
                }
            }
        }
    }
}

private extension NotificationManager {
    func reminderIdentifier(for subscription: Subscription) -> String {
        "renewal-\(subscription.persistentModelID)"
    }

    func reminderIdentifier(for subscription: Subscription, daysBefore: Int) -> String {
        "renewal-\(subscription.persistentModelID)-\(daysBefore)"
    }

    func reminderSettingsKey(for subscription: Subscription) -> String {
        "\(reminderSettingsPrefix)\(subscription.persistentModelID)"
    }

    func reminderIdentifiers(for subscription: Subscription) -> [String] {
        [reminderIdentifier(for: subscription)] + Array(0...7).map { reminderIdentifier(for: subscription, daysBefore: $0) }
    }

    func reminderTitle(for subscription: Subscription, daysBefore: Int) -> String {
        if daysBefore == 0 {
            return "\(subscription.service.name) の更新日です"
        }
        return "\(subscription.service.name) の更新日まであと\(daysBefore)日です"
    }

    func reminderBody(for subscription: Subscription) -> String {
        "¥\(subscription.price) が請求される予定です"
    }

    func scheduledDate(for subscription: Subscription, daysBefore: Int, hour: Int, minute: Int) -> Date? {
        guard subscription.isActive,
              let nextRenewalDate = subscription.nextRenewalDate(calendar: calendar),
              let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: nextRenewalDate),
              let scheduledDate = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: reminderDate
              ),
              scheduledDate > .now else {
            return nil
        }

        return scheduledDate
    }
}
