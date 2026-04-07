import SwiftUI

struct ServiceManagementMenuItem: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let iconName: String
    let topColor: Color
    let iconColor: Color
    let borderColor: Color
    let serviceType: ServiceType
}

enum ServiceManagementHomeViewDataBuilder {
    static let title = "管理するサービスを選択"

    static func makeMenuItems() -> [ServiceManagementMenuItem] {
        ServiceTypeCardCatalog.displayOrder.map { serviceType in
            let definition = ServiceTypeCardCatalog.definition(for: serviceType)
            let appearance = ServiceTypeCardCatalog.managementAppearance(for: serviceType)

            return ServiceManagementMenuItem(
                id: definition.id,
                title: definition.title,
                subtitle: definition.managementSubtitle,
                iconName: definition.iconName,
                topColor: appearance.topColor,
                iconColor: appearance.iconColor,
                borderColor: appearance.borderColor,
                serviceType: serviceType
            )
        }
    }
}
