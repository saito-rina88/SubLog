import SwiftUI

struct RecordTypeOption: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let topColor: Color
    let iconColor: Color
    let borderColor: Color
    let serviceType: ServiceType
}

enum Step1TypeSelectViewDataBuilder {
    static let title = "支払いタイプを選択"

    static func makeOptions(theme: AppTheme) -> [RecordTypeOption] {
        ServiceTypeCardCatalog.displayOrder.map { serviceType in
            let appearance = ServiceTypeCardCatalog.recordAppearance(for: serviceType, theme: theme)
            let definition = ServiceTypeCardCatalog.definition(for: serviceType)

            return RecordTypeOption(
                id: definition.id,
                title: definition.title,
                subtitle: definition.recordSubtitle,
                iconName: definition.iconName,
                topColor: appearance.topColor,
                iconColor: appearance.iconColor,
                borderColor: appearance.borderColor,
                serviceType: serviceType
            )
        }
    }
}
