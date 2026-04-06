import Foundation
import SwiftData

@Model
final class PaymentCustomType {
    var name: String
    var sortOrder: Int
    var createdAt: Date

    init(name: String, sortOrder: Int = 0) {
        self.name = name
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}
