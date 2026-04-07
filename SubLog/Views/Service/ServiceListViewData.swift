import Foundation

struct ServiceListItemData {
    let service: Service
    let totalAmount: Int
}

struct ServiceListViewData {
    let filteredServices: [Service]
    let serviceItems: [ServiceListItemData]
    let activeServiceCount: Int
    let canAddService: Bool
    let canReorderServices: Bool
    let isEmptyForCurrentType: Bool
    let emptyStateTitle: String
    let sectionTitle: String
}

enum ServiceListViewDataBuilder {
    static func build(
        services: [Service],
        currentServiceType: ServiceType,
        searchText: String,
        managementMode: Bool,
        isPremium: Bool
    ) -> ServiceListViewData {
        let activeServices = services.filter { !$0.isArchived }
        let trimmedSearchText = searchText.trimmingCharacters(in: .whitespacesAndNewlines)

        let filteredServices = activeServices
            .filter { $0.serviceType == currentServiceType }
            .filter { service in
                trimmedSearchText.isEmpty || service.name.localizedCaseInsensitiveContains(trimmedSearchText)
            }
            .sorted { lhs, rhs in
                if managementMode {
                    if lhs.sortOrder == rhs.sortOrder {
                        return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                    }
                    return lhs.sortOrder < rhs.sortOrder
                }

                return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
            }

        return ServiceListViewData(
            filteredServices: filteredServices,
            serviceItems: filteredServices.map { service in
                ServiceListItemData(
                    service: service,
                    totalAmount: service.payments.reduce(0) { $0 + $1.amount }
                )
            },
            activeServiceCount: activeServices.count,
            canAddService: isPremium || activeServices.count < 8,
            canReorderServices: trimmedSearchText.isEmpty && !filteredServices.isEmpty,
            isEmptyForCurrentType: filteredServices.isEmpty,
            emptyStateTitle: emptyStateTitle(for: currentServiceType),
            sectionTitle: sectionTitle(for: currentServiceType)
        )
    }

    static func sortedActiveServices(for type: ServiceType, services: [Service]) -> [Service] {
        services
            .filter { $0.serviceType == type && !$0.isArchived }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }
    }

    static func needsOrderNormalization(for services: [Service]) -> Bool {
        services.enumerated().contains { index, service in
            service.sortOrder != index
        }
    }

    private static func emptyStateTitle(for serviceType: ServiceType) -> String {
        switch serviceType {
        case .subscription:
            return "まだ定期支払いのサービスが登録されていません"
        case .game:
            return "まだ単発支払いのサービスが登録されていません"
        }
    }

    private static func sectionTitle(for serviceType: ServiceType) -> String {
        switch serviceType {
        case .subscription:
            return "定期支払いのサービス"
        case .game:
            return "単発支払いのサービス"
        }
    }
}
