import Foundation
import SwiftData

@Model
final class Service {
    var name: String
    var category: Category
    var serviceType: ServiceType
    var sortOrder: Int = 0
    var isArchived: Bool = false
    var icon: Data?
    var memo: String?
    var createdAt: Date

    @Relationship(deleteRule: .cascade)
    var subscriptions: [Subscription] = []

    @Relationship(deleteRule: .cascade)
    var payments: [Payment] = []

    @Relationship(deleteRule: .cascade)
    var gachaTemplates: [GachaTemplate] = []

    init(
        name: String,
        category: Category,
        serviceType: ServiceType,
        sortOrder: Int = 0,
        isArchived: Bool = false,
        icon: Data? = nil,
        memo: String? = nil,
        createdAt: Date = .now
    ) {
        self.name = name
        self.category = category
        self.serviceType = serviceType
        self.sortOrder = sortOrder
        self.isArchived = isArchived
        self.icon = icon
        self.memo = memo
        self.createdAt = createdAt
    }
}
