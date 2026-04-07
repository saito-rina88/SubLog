import Foundation
import SwiftData

struct SubscriptionReminderInitialState {
    let isEnabled: Bool
    let time: Date
    let daysBefore: Int
}

struct SubscriptionDetailViewData {
    let nextRenewalDate: Date?
    let daysUntilRenewal: Int?
    let nextRenewalDateText: String?
    let renewalBadgeText: String?
    let isRenewalSoon: Bool
    let canceledDateText: String?
    let reminderSummaryText: String
}

enum SubscriptionDetailViewDataBuilder {
    static func build(
        subscription: Subscription,
        reminderDaysBefore: Int,
        calendar: Calendar = .current
    ) -> SubscriptionDetailViewData {
        let nextRenewalDate = nextRenewalDate(for: subscription, calendar: calendar)
        let daysUntilRenewal = nextRenewalDate.flatMap {
            calendar.dateComponents([.day], from: Date(), to: $0).day
        }

        return SubscriptionDetailViewData(
            nextRenewalDate: nextRenewalDate,
            daysUntilRenewal: daysUntilRenewal,
            nextRenewalDateText: nextRenewalDate.map(dateString),
            renewalBadgeText: daysUntilRenewal.map { "あと\($0)日" },
            isRenewalSoon: (daysUntilRenewal ?? .max) <= 7,
            canceledDateText: subscription.canceledDate.map(dateString),
            reminderSummaryText: "\(reminderDaysBefore)日前と当日に通知します"
        )
    }

    static func initialReminderState(
        for subscription: Subscription,
        notificationManager: NotificationManager
    ) -> SubscriptionReminderInitialState {
        let defaultTime = Calendar.current.date(
            bySettingHour: 9,
            minute: 0,
            second: 0,
            of: Date()
        ) ?? Date()

        guard let settings = notificationManager.reminderSettings(for: subscription) else {
            return SubscriptionReminderInitialState(isEnabled: false, time: defaultTime, daysBefore: 3)
        }

        let reminderTime = Calendar.current.date(
            bySettingHour: settings.hour,
            minute: settings.minute,
            second: 0,
            of: Date()
        ) ?? defaultTime

        return SubscriptionReminderInitialState(
            isEnabled: true,
            time: reminderTime,
            daysBefore: max(settings.daysBefore, 1)
        )
    }

    nonisolated static func dateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    private static func nextRenewalDate(for subscription: Subscription, calendar: Calendar) -> Date? {
        guard subscription.isActive else { return nil }

        let interval = subscription.renewalInterval
        var components = DateComponents()

        switch interval.unit {
        case .day:
            components.day = interval.value
        case .week:
            components.weekOfYear = interval.value
        case .month:
            components.month = interval.value
        case .year:
            components.year = interval.value
        }

        var base = subscription.startDate
        let now = Date()

        while base <= now {
            guard let next = calendar.date(byAdding: components, to: base), next > base else {
                break
            }
            base = next
        }

        return base
    }
}
