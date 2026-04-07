import Foundation
import SwiftData

@Model
final class GachaTemplate {
    // Persisted attributes
    var label: String
    var amount: Int?
    var sortOrder: Int = 0

    // Parent relationship
    var service: Service

    init(
        label: String,
        amount: Int? = nil,
        service: Service,
        sortOrder: Int = 0
    ) {
        self.label = label
        self.amount = amount
        self.service = service
        self.sortOrder = sortOrder
    }
}
