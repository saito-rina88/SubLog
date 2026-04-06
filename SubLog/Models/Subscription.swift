import Foundation
import SwiftData

@Model
final class Subscription {
    var label: String
    var billingType: BillingType
    var renewalInterval: RenewalInterval
    var price: Int
    var startDate: Date
    var isActive: Bool = true
    var canceledDate: Date?
    var memo: String?
    var service: Service
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
