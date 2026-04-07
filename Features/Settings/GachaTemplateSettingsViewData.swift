import Foundation
import SwiftData

struct GachaTemplateServiceRowData: Identifiable {
    let id: PersistentIdentifier
    let service: Service
    let hasTemplates: Bool
}

struct GachaTemplateSettingsViewData {
    let gameServices: [Service]
    let serviceRows: [GachaTemplateServiceRowData]
    let isEmpty: Bool
    let emptyStateTitle: String
}

enum GachaTemplateSettingsViewDataBuilder {
    static func build(services: [Service]) -> GachaTemplateSettingsViewData {
        let gameServices = services.filter { $0.serviceType == .game && !$0.isArchived }

        return GachaTemplateSettingsViewData(
            gameServices: gameServices,
            serviceRows: gameServices.map { service in
                GachaTemplateServiceRowData(
                    id: service.persistentModelID,
                    service: service,
                    hasTemplates: !service.gachaTemplates.isEmpty
                )
            },
            isEmpty: gameServices.isEmpty,
            emptyStateTitle: "購入内容テンプレートを利用できるサービスがありません"
        )
    }
}
