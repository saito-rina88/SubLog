import Foundation
import SwiftData

@Model
final class Payment {
    // Persisted attributes
    var date: Date
    var amount: Int
    // Display-oriented payment content text, not a type identifier or foreign key.
    // This can contain a fixed label ("サブスク更新"), a short candidate name ("ガチャ"),
    // or a composed summary string ("10連 ×2、月パック").
    var type: String
    var itemName: String?
    var memo: String?
    var screenshotData: Data?

    // Parent relationships
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
