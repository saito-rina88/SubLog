import Foundation
import SwiftData

struct AddGachaTemplateViewData {
    let gameServices: [Service]
    let selectedService: Service?
    let amountValue: Int
    let trimmedAmountText: String
    let trimmedLabel: String
    let canSave: Bool
}

enum AddGachaTemplateViewDataBuilder {
    static func build(
        services: [Service],
        selectedServiceID: PersistentIdentifier?,
        label: String,
        amountText: String
    ) -> AddGachaTemplateViewData {
        let gameServices = services
            .filter { $0.serviceType == .game && !$0.isArchived }
            .sorted { $0.name < $1.name }
        let trimmedLabel = label.trimmedText
        let trimmedAmountText = amountText.trimmedText
        let amountValue = ViewDataCommon.intValue(from: amountText)
        let selectedService = selectedServiceID.flatMap { id in
            gameServices.first { $0.persistentModelID == id }
        }

        return AddGachaTemplateViewData(
            gameServices: gameServices,
            selectedService: selectedService,
            amountValue: amountValue,
            trimmedAmountText: trimmedAmountText,
            trimmedLabel: trimmedLabel,
            canSave: !trimmedLabel.isEmpty &&
                (trimmedAmountText.isEmpty || amountValue > 0) &&
                selectedServiceID != nil
        )
    }
}
