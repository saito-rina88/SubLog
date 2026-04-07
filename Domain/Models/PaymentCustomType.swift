import Foundation
import SwiftData

@Model
final class PaymentCustomType {
    // Persisted attributes
    // User-managed candidate/template name used when entering payment content.
    // This is not a foreign key target for Payment.type.
    var name: String
    var sortOrder: Int
    var createdAt: Date

    init(
        name: String,
        sortOrder: Int = 0,
        createdAt: Date = .now
    ) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = createdAt
    }
}
