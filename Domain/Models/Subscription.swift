import Foundation
import SwiftData

@Model
final class Subscription {
    // Persisted attributes
    var label: String
    var billingType: BillingType
    var renewalInterval: RenewalInterval
    var price: Int
    var startDate: Date
    var isActive: Bool = true
    var canceledDate: Date?
    var memo: String?

    // Parent / child relationships
    var service: Service

    @Relationship(inverse: \Payment.subscription)
    var payments: [Payment] = []

    init(
        label: String,
        billingType: BillingType,
        price: Int,
        startDate: Date,
        service: Service,
        renewalInterval: RenewalInterval? = nil,
        memo: String? = nil
    ) {
        self.label = label
        self.billingType = billingType
        self.renewalInterval = renewalInterval ?? billingType.defaultInterval
        self.price = price
        self.startDate = startDate
        self.service = service
        self.memo = memo
    }
}

extension Subscription {
    func nextRenewalDate(calendar: Calendar = .current, now: Date = .now) -> Date? {
        guard isActive else { return nil }

        let component = renewalInterval.unit.calendarComponent
        var candidate = startDate

        while candidate <= now {
            guard let nextDate = calendar.date(
                byAdding: component,
                value: renewalInterval.value,
                to: candidate
            ) else {
                return nil
            }
            candidate = nextDate
        }

        return candidate
    }
}
