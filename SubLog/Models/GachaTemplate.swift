import Foundation
import SwiftData

@Model
final class GachaTemplate {
    var label: String
    var amount: Int?
    var sortOrder: Int = 0
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
