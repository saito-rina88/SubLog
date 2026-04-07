import Foundation

struct AddServiceViewData {
    let trimmedName: String
    let selectedCategory: Category
    let nextSortOrder: Int
    let canSave: Bool
    let iconButtonTitle: String
}

enum AddServiceViewDataBuilder {
    static let defaultGameTemplates: [(label: String, amount: Int?)] = [
        ("アイテム購入", nil),
        ("マンスリーパス", 610),
        ("シーズンパス", 1_220)
    ]

    static func build(
        services: [Service],
        name: String,
        serviceType: ServiceType,
        presetIconCategory: Category?,
        iconData: Data?
    ) -> AddServiceViewData {
        let trimmedName = name.trimmedText

        return AddServiceViewData(
            trimmedName: trimmedName,
            selectedCategory: selectedCategory(for: serviceType, presetIconCategory: presetIconCategory),
            nextSortOrder: nextSortOrder(for: serviceType, services: services),
            canSave: !trimmedName.isEmpty,
            iconButtonTitle: iconData == nil ? "タップして設定" : "タップして変更"
        )
    }

    private static func nextSortOrder(for serviceType: ServiceType, services: [Service]) -> Int {
        (services
            .filter { $0.serviceType == serviceType && !$0.isArchived }
            .map(\.sortOrder)
            .max() ?? -1) + 1
    }

    private static func selectedCategory(for serviceType: ServiceType, presetIconCategory: Category?) -> Category {
        if let presetIconCategory {
            return presetIconCategory
        }

        switch serviceType {
        case .game:
            return .game
        case .subscription:
            return .other
        }
    }
}
