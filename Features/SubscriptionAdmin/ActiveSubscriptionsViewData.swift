import SwiftData
import SwiftUI

enum ActiveSubscriptionsSortType: CaseIterable, Identifiable {
    case nextRenewal
    case priceDescending
    case priceAscending
    case name

    var id: Self { self }

    var title: String {
        switch self {
        case .nextRenewal:
            return "次回更新順"
        case .priceDescending:
            return "月額降順"
        case .priceAscending:
            return "月額昇順"
        case .name:
            return "名前順"
        }
    }
}

struct ActiveSubscriptionRowData: Identifiable {
    let service: Service
    let subscription: Subscription
    let nextRenewalDate: Date
    let nextRenewalDateText: String
    let daysUntilRenewal: Int
    let daysText: String
    let daysColor: Color
    let daysBackground: Color
    let priceText: String

    var id: PersistentIdentifier { subscription.persistentModelID }
}

struct ActiveSubscriptionsViewData {
    let items: [ActiveSubscriptionRowData]
    let monthlyTotalText: String
}

enum ActiveSubscriptionsViewDataBuilder {
    static func build(
        services: [Service],
        selectedSort: ActiveSubscriptionsSortType,
        calendar: Calendar = .current
    ) -> ActiveSubscriptionsViewData {
        let items = sortedItems(
            from: services,
            sortType: selectedSort,
            calendar: calendar
        )

        return ActiveSubscriptionsViewData(
            items: items,
            monthlyTotalText: ViewDataCommon.yenString(
                from: items.reduce(0) { $0 + $1.subscription.price }
            )
        )
    }

    static func sortedItems(
        from services: [Service],
        sortType: ActiveSubscriptionsSortType,
        calendar: Calendar
    ) -> [ActiveSubscriptionRowData] {
        let items = services
            .filter { !$0.isArchived }
            .flatMap { service in
                service.subscriptions
                    .filter { $0.isActive }
                    .map { subscription in
                        makeItem(service: service, subscription: subscription, calendar: calendar)
                    }
            }

        switch sortType {
        case .nextRenewal:
            return items.sorted { lhs, rhs in
                if lhs.nextRenewalDate == rhs.nextRenewalDate {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.nextRenewalDate < rhs.nextRenewalDate
            }
        case .priceDescending:
            return items.sorted { lhs, rhs in
                if lhs.subscription.price == rhs.subscription.price {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.subscription.price > rhs.subscription.price
            }
        case .priceAscending:
            return items.sorted { lhs, rhs in
                if lhs.subscription.price == rhs.subscription.price {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.subscription.price < rhs.subscription.price
            }
        case .name:
            return items.sorted { $0.service.name < $1.service.name }
        }
    }

    static func makeItem(
        service: Service,
        subscription: Subscription,
        calendar: Calendar
    ) -> ActiveSubscriptionRowData {
        let nextRenewalDate = subscription.nextRenewalDate(calendar: calendar) ?? subscription.startDate
        let daysUntilRenewal = calendar.dateComponents([.day], from: .now, to: nextRenewalDate).day ?? 0

        return ActiveSubscriptionRowData(
            service: service,
            subscription: subscription,
            nextRenewalDate: nextRenewalDate,
            nextRenewalDateText: ViewDataCommon.slashDateString(from: nextRenewalDate),
            daysUntilRenewal: daysUntilRenewal,
            daysText: daysUntilRenewal <= 0 ? "今日" : "\(daysUntilRenewal)日",
            daysColor: daysColor(for: daysUntilRenewal),
            daysBackground: daysBackground(for: daysUntilRenewal),
            priceText: ViewDataCommon.yenString(from: subscription.price)
        )
    }

    static func daysColor(for days: Int) -> Color {
        if days <= 3 {
            return Color(red: 0.82, green: 0.28, blue: 0.28)
        }
        if days <= 10 {
            return Color(red: 0.82, green: 0.49, blue: 0.12)
        }
        return Color(red: 0.43, green: 0.45, blue: 0.52)
    }

    static func daysBackground(for days: Int) -> Color {
        if days <= 3 {
            return Color(red: 1.0, green: 0.91, blue: 0.91)
        }
        if days <= 10 {
            return Color(red: 1.0, green: 0.94, blue: 0.86)
        }
        return Color(red: 0.95, green: 0.95, blue: 0.97)
    }
}
