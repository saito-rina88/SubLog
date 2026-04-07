import Foundation

struct Step2ServiceSelectViewData {
    let filteredServices: [Service]
    let activeServiceCount: Int
    let canAddService: Bool
    let isSearchActive: Bool

    var canReorderServices: Bool {
        !isSearchActive && !filteredServices.isEmpty
    }
}

enum Step2ServiceSelectViewDataBuilder {
    static func build(
        allServices: [Service],
        serviceType: ServiceType,
        searchText: String,
        isPremium: Bool
    ) -> Step2ServiceSelectViewData {
        let activeServices = allServices.filter { !$0.isArchived }
        let servicesForType = activeServices.filter { $0.serviceType == serviceType }
        let trimmedSearchText = searchText.trimmedText

        let filteredServices = servicesForType
            .filter { service in
                trimmedSearchText.isEmpty || service.name.localizedCaseInsensitiveContains(trimmedSearchText)
            }
            .sorted { lhs, rhs in
                if lhs.sortOrder == rhs.sortOrder {
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                return lhs.sortOrder < rhs.sortOrder
            }

        return Step2ServiceSelectViewData(
            filteredServices: filteredServices,
            activeServiceCount: activeServices.count,
            canAddService: isPremium || activeServices.count < AppLimits.freeServiceLimit,
            isSearchActive: !trimmedSearchText.isEmpty
        )
    }

    static func needsOrderNormalization(services: [Service]) -> Bool {
        services.enumerated().contains { index, service in
            service.sortOrder != index
        }
    }
}
