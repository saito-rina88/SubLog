import Foundation
import SwiftData

struct Step3bGameDetailViewData {
    let service: Service?
    let sortedTemplates: [GachaTemplate]
    let selectedTemplates: [GachaTemplate]
    let amountValue: Int
    let hasSelectedTemplateWithoutAmount: Bool
    let purchaseSummary: String
    let canSave: Bool
}

enum Step3bGameDetailViewDataBuilder {
    static func build(
        allServices: [Service],
        serviceID: PersistentIdentifier,
        selectedTemplateIDs: Set<PersistentIdentifier>,
        templateQuantities: [PersistentIdentifier: Int],
        amountText: String
    ) -> Step3bGameDetailViewData {
        let service = allServices.first { $0.persistentModelID == serviceID }
        let sortedTemplates = sortedTemplates(for: service)
        let selectedTemplates = sortedTemplates.filter { selectedTemplateIDs.contains($0.persistentModelID) }
        let amountValue = ViewDataCommon.intValue(from: amountText)

        return Step3bGameDetailViewData(
            service: service,
            sortedTemplates: sortedTemplates,
            selectedTemplates: selectedTemplates,
            amountValue: amountValue,
            hasSelectedTemplateWithoutAmount: selectedTemplates.contains(where: { $0.amount == nil }),
            purchaseSummary: purchaseSummary(for: selectedTemplates, templateQuantities: templateQuantities),
            canSave: amountValue > 0 && service != nil
        )
    }

    static func syncedSelection(
        sortedTemplates: [GachaTemplate],
        selectedTemplateIDs: Set<PersistentIdentifier>,
        templateQuantities: [PersistentIdentifier: Int]
    ) -> (selectedTemplateIDs: Set<PersistentIdentifier>, templateQuantities: [PersistentIdentifier: Int]) {
        let currentIDs = Set(sortedTemplates.map(\.persistentModelID))
        let syncedIDs = selectedTemplateIDs.intersection(currentIDs)
        let syncedQuantities = templateQuantities.filter { currentIDs.contains($0.key) }
        return (syncedIDs, syncedQuantities)
    }

    static func selectedTemplateTotal(
        selectedTemplates: [GachaTemplate],
        templateQuantities: [PersistentIdentifier: Int]
    ) -> Int {
        selectedTemplates.reduce(0) { partialResult, template in
            let quantity = templateQuantities[template.persistentModelID, default: 1]
            return partialResult + (template.amount ?? 0) * quantity
        }
    }

    private static func sortedTemplates(for service: Service?) -> [GachaTemplate] {
        guard let service else { return [] }
        return service.gachaTemplates.sorted { lhs, rhs in
            if lhs.sortOrder == rhs.sortOrder {
                return lhs.label < rhs.label
            }
            return lhs.sortOrder < rhs.sortOrder
        }
    }

    private static func purchaseSummary(
        for selectedTemplates: [GachaTemplate],
        templateQuantities: [PersistentIdentifier: Int]
    ) -> String {
        selectedTemplates.map { template in
            let quantity = templateQuantities[template.persistentModelID, default: 1]
            return quantity > 1 ? "\(template.label) ×\(quantity)" : template.label
        }
        .joined(separator: "、")
    }
}
