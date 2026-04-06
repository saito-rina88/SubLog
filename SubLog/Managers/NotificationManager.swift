import Combine
import Foundation
import SwiftData
import UserNotifications

@MainActor
final class NotificationManager: ObservableObject {
    struct ReminderSettings: Codable {
        let hour: Int
        let minute: Int
        let daysBefore: Int
    }

    private let center = UNUserNotificationCenter.current()
    private let reminderEnabledKey = "reminderEnabled"
    private let reminderSettingsPrefix = "reminderSettings-"
    private let calendar = Calendar.current

    func requestAuthorization() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .badge, .sound])
        } catch {
            return false
        }
    }

    func scheduleRenewalReminder(for subscription: Subscription, service: Service) async {
        let identifier = reminderIdentifier(for: subscription)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard UserDefaults.standard.bool(forKey: reminderEnabledKey),
              subscription.isActive,
              let nextRenewalDate = nextRenewalDate(for: subscription),
              let reminderDate = calendar.date(byAdding: .day, value: -1, to: nextRenewalDate),
              let scheduledDate = calendar.date(
                bySettingHour: 9,
                minute: 0,
                second: 0,
                of: reminderDate
              ),
              scheduledDate > .now else {
            return
        }

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )

        let content = UNMutableNotificationContent()
        content.title = "\(service.name) の更新日が明日です"
        content.body = "¥\(subscription.price) が請求される予定です"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await center.add(request)
    }

    func scheduleNotification(for subscription: Subscription, daysBefore: Int, hour: Int, minute: Int) async {
        let identifier = reminderIdentifier(for: subscription, daysBefore: daysBefore)
        center.removePendingNotificationRequests(withIdentifiers: [identifier])

        guard subscription.isActive,
              let nextRenewalDate = nextRenewalDate(for: subscription),
              let reminderDate = calendar.date(byAdding: .day, value: -daysBefore, to: nextRenewalDate),
              let scheduledDate = calendar.date(
                bySettingHour: hour,
                minute: minute,
                second: 0,
                of: reminderDate
              ),
              scheduledDate > .now else {
            return
        }

        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )

        let content = UNMutableNotificationContent()
        if daysBefore == 0 {
            content.title = "\(subscription.service.name) の更新日です"
        } else {
            content.title = "\(subscription.service.name) の更新日まであと\(daysBefore)日です"
        }
        content.body = "¥\(subscription.price) が請求される予定です"
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        try? await center.add(request)
    }

    func cancelReminder(for subscription: Subscription) async {
        center.removePendingNotificationRequests(withIdentifiers: reminderIdentifiers(for: subscription))
    }

    func reminderSettings(for subscription: Subscription) -> ReminderSettings? {
        guard let data = UserDefaults.standard.data(forKey: reminderSettingsKey(for: subscription)),
              let settings = try? JSONDecoder().decode(ReminderSettings.self, from: data) else {
            return nil
        }
        return settings
    }

    func saveReminderSettings(for subscription: Subscription, hour: Int, minute: Int, daysBefore: Int) {
        let settings = ReminderSettings(hour: hour, minute: minute, daysBefore: daysBefore)
        guard let data = try? JSONEncoder().encode(settings) else { return }
        UserDefaults.standard.set(data, forKey: reminderSettingsKey(for: subscription))
        refreshReminderEnabledFlag()
    }

    func removeReminderSettings(for subscription: Subscription) {
        UserDefaults.standard.removeObject(forKey: reminderSettingsKey(for: subscription))
        refreshReminderEnabledFlag()
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

    func refreshReminderEnabledFlag() {
        let hasAnySettings = UserDefaults.standard.dictionaryRepresentation().keys.contains { key in
            key.hasPrefix(reminderSettingsPrefix)
        }
        UserDefaults.standard.set(hasAnySettings, forKey: reminderEnabledKey)
    }

    func nextRenewalDate(for subscription: Subscription) -> Date? {
        let component = subscription.renewalInterval.unit.calendarComponent
        var candidate = subscription.startDate

        while candidate <= .now {
            guard let nextDate = calendar.date(
                byAdding: component,
                value: subscription.renewalInterval.value,
                to: candidate
            ) else {
                return nil
            }
            candidate = nextDate
        }

        return candidate
    }
}
