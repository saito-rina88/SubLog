import Foundation
import SwiftData

struct Step3aSubscDetailViewData {
    let service: Service?
    let activeSubscription: Subscription?
    let amountValue: Int
    let canSave: Bool
    let renewalDisplayText: String
    let reminderSummaryText: String
}

enum Step3aSubscDetailViewDataBuilder {
    static func build(
        allServices: [Service],
        serviceID: PersistentIdentifier,
        amountText: String,
        renewalValueText: String,
        renewalUnit: RenewalIntervalUnit,
        reminderDaysBefore: Int
    ) -> Step3aSubscDetailViewData {
        let service = allServices.first { $0.persistentModelID == serviceID }
        let activeSubscription = service?.subscriptions.first(where: { $0.isActive })
        let amountValue = Int(amountText) ?? 0
        let normalizedRenewalValue = normalizedRenewalValue(from: renewalValueText)

        return Step3aSubscDetailViewData(
            service: service,
            activeSubscription: activeSubscription,
            amountValue: amountValue,
            canSave: amountValue > 0 && service != nil,
            renewalDisplayText: activeSubscription?.renewalInterval.displayText
                ?? RenewalInterval(value: normalizedRenewalValue, unit: renewalUnit).displayText,
            reminderSummaryText: "\(reminderDaysBefore)日前と当日に通知します"
        )
    }

    static func normalizedRenewalValue(from text: String) -> Int {
        max(Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 1, 1)
    }

    static func billingType(for renewalInterval: RenewalInterval) -> BillingType {
        switch (renewalInterval.value, renewalInterval.unit) {
        case (7, .day), (1, .week):
            return .weekly
        case (1, .month):
            return .monthly
        case (1, .year):
            return .annual
        default:
            return .seasonal
        }
    }

    static var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.firstWeekday = 2
        return calendar
    }
}
