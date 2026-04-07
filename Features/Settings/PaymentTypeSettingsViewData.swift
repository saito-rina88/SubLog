import Foundation
import SwiftData

struct PaymentTypeRowData: Identifiable {
    let id: PersistentIdentifier
    let type: PaymentCustomType
    let displayName: String
}

struct PaymentTypeSettingsViewData {
    let rows: [PaymentTypeRowData]
    let listHeight: CGFloat
    let isEmpty: Bool
}

enum PaymentTypeSettingsViewDataBuilder {
    static func build(customTypes: [PaymentCustomType]) -> PaymentTypeSettingsViewData {
        let rows = customTypes.map { type in
            PaymentTypeRowData(
                id: type.persistentModelID,
                type: type,
                displayName: type.name
            )
        }

        return PaymentTypeSettingsViewData(
            rows: rows,
            listHeight: CGFloat(customTypes.count) * 56 + 16,
            isEmpty: rows.isEmpty
        )
    }

    static func normalizedName(_ name: String) -> String {
        name.trimmedText
    }

    static func canSave(name: String) -> Bool {
        !normalizedName(name).isEmpty
    }
}
