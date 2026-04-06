import Foundation
import SwiftData

@Model
final class Payment {
    var date: Date
    var amount: Int
    var type: String
    var itemName: String?
    var memo: String?
    var screenshotData: Data?
    var service: Service
    var subscription: Subscription?

    init(
        date: Date,
        amount: Int,
        type: String,
        service: Service,
        subscription: Subscription? = nil,
        itemName: String? = nil,
        memo: String? = nil
    ) {
        self.date = date
        self.amount = amount
        self.type = type
        self.service = service
        self.subscription = subscription
        self.itemName = itemName
        self.memo = memo
    }
}
