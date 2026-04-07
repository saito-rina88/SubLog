import Foundation
import UserNotifications

extension NotificationManager {
    struct ReminderSettings: Codable {
        let hour: Int
        let minute: Int
        let daysBefore: Int
    }
}

enum NotificationReminderSettingsStore {
    static func isReminderEnabled(
        userDefaults: UserDefaults,
        reminderEnabledKey: String
    ) -> Bool {
        userDefaults.bool(forKey: reminderEnabledKey)
    }

    static func loadSettings(
        userDefaults: UserDefaults,
        key: String
    ) -> NotificationManager.ReminderSettings? {
        guard let data = userDefaults.data(forKey: key),
              let settings = try? JSONDecoder().decode(NotificationManager.ReminderSettings.self, from: data) else {
            return nil
        }
        return settings
    }

    static func saveSettings(
        _ settings: NotificationManager.ReminderSettings,
        userDefaults: UserDefaults,
        key: String,
        reminderEnabledKey: String,
        reminderSettingsPrefix: String
    ) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: key)
        refreshReminderEnabledFlag(
            userDefaults: userDefaults,
            reminderEnabledKey: reminderEnabledKey,
            reminderSettingsPrefix: reminderSettingsPrefix
        )
    }

    static func removeSettings(
        userDefaults: UserDefaults,
        key: String,
        reminderEnabledKey: String,
        reminderSettingsPrefix: String
    ) {
        userDefaults.removeObject(forKey: key)
        refreshReminderEnabledFlag(
            userDefaults: userDefaults,
            reminderEnabledKey: reminderEnabledKey,
            reminderSettingsPrefix: reminderSettingsPrefix
        )
    }

    private static func refreshReminderEnabledFlag(
        userDefaults: UserDefaults,
        reminderEnabledKey: String,
        reminderSettingsPrefix: String
    ) {
        let hasAnySettings = userDefaults.dictionaryRepresentation().keys.contains { key in
            key.hasPrefix(reminderSettingsPrefix)
        }
        userDefaults.set(hasAnySettings, forKey: reminderEnabledKey)
    }
}

enum NotificationReminderRequestFactory {
    static func makeRequest(
        identifier: String,
        title: String,
        body: String,
        scheduledDate: Date,
        calendar: Calendar
    ) -> UNNotificationRequest {
        let components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: scheduledDate
        )

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        return UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
    }
}
