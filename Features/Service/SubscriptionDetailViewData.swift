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
        let nextRenewalDate = subscription.nextRenewalDate(calendar: calendar)
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
            reminderSummaryText: MessageCatalog.reminderSummary(daysBefore: reminderDaysBefore)
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
        ViewDataCommon.slashDateString(from: date)
    }
}
