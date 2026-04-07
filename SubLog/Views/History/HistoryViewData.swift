import Foundation
import SwiftData

enum HistoryFilterType: String, CaseIterable, Identifiable {
    case all = "すべて"
    case subscription = "定期"
    case game = "単発"

    var id: Self { self }

    func matches(_ serviceType: ServiceType) -> Bool {
        switch self {
        case .all:
            return true
        case .game:
            return serviceType == .game
        case .subscription:
            return serviceType == .subscription
        }
    }
}

enum HistorySortOrder {
    case newestFirst
    case oldestFirst
}

struct HistoryPaymentWithService: Identifiable {
    let payment: Payment
    let service: Service

    var id: PersistentIdentifier { payment.persistentModelID }
}

struct HistoryMonthSection {
    let monthStart: Date
    let items: [HistoryPaymentWithService]
    let total: Int
}

struct HistoryListData {
    let allPayments: [HistoryPaymentWithService]
    let filteredPaymentsBase: [HistoryPaymentWithService]
    let filteredPayments: [HistoryPaymentWithService]
    let availableMonths: [Date]
    let groupedByMonth: [HistoryMonthSection]

    var currentMonthTotal: Int {
        filteredPayments.reduce(0) { $0 + $1.payment.amount }
    }

    var currentMonthTotalText: String {
        currentMonthTotal.formatted(.currency(code: "JPY"))
    }

    func syncedMonth(from selectedMonth: Date, calendar: Calendar = .current) -> Date {
        guard !availableMonths.isEmpty else {
            return calendar.dateInterval(of: .month, for: .now)?.start ?? .now
        }

        if availableMonths.contains(where: { calendar.isDate($0, equalTo: selectedMonth, toGranularity: .month) }) {
            return selectedMonth
        }

        return availableMonths[0]
    }

    func selectedMonthIndex(for selectedMonth: Date, calendar: Calendar = .current) -> Int? {
        availableMonths.firstIndex {
            calendar.isDate($0, equalTo: selectedMonth, toGranularity: .month)
        }
    }

    func month(before selectedMonth: Date, calendar: Calendar = .current) -> Date? {
        guard let index = selectedMonthIndex(for: selectedMonth, calendar: calendar) else { return nil }
        let nextIndex = index + 1
        guard availableMonths.indices.contains(nextIndex) else { return nil }
        return availableMonths[nextIndex]
    }

    func month(after selectedMonth: Date, calendar: Calendar = .current) -> Date? {
        guard let index = selectedMonthIndex(for: selectedMonth, calendar: calendar) else { return nil }
        let nextIndex = index - 1
        guard availableMonths.indices.contains(nextIndex) else { return nil }
        return availableMonths[nextIndex]
    }
}

enum HistoryListDataBuilder {
    static func make(
        services: [Service],
        searchText: String,
        selectedFilter: HistoryFilterType,
        selectedMonth: Date,
        sortOrder: HistorySortOrder,
        calendar: Calendar = .current
    ) -> HistoryListData {
        let allPayments = services
            .flatMap { service in
                service.payments.map { HistoryPaymentWithService(payment: $0, service: service) }
            }
            .sorted { lhs, rhs in
                if lhs.payment.date == rhs.payment.date {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.payment.date > rhs.payment.date
            }

        let filteredPaymentsBase = allPayments.filter { item in
            guard selectedFilter.matches(item.service.serviceType) else {
                return false
            }

            guard !searchText.isEmpty else {
                return true
            }

            let serviceHit = item.service.name.localizedCaseInsensitiveContains(searchText)
            let itemNameHit = item.payment.itemName?.localizedCaseInsensitiveContains(searchText) ?? false
            let memoHit = item.payment.memo?.localizedCaseInsensitiveContains(searchText) ?? false
            return serviceHit || itemNameHit || memoHit
        }

        let availableMonths = Array(
            Set(
                filteredPaymentsBase.map {
                    calendar.dateInterval(of: .month, for: $0.payment.date)?.start ?? $0.payment.date
                }
            )
        )
        .sorted(by: >)

        let syncedMonth: Date = {
            guard !availableMonths.isEmpty else {
                return calendar.dateInterval(of: .month, for: .now)?.start ?? .now
            }

            if availableMonths.contains(where: { calendar.isDate($0, equalTo: selectedMonth, toGranularity: .month) }) {
                return selectedMonth
            }

            return availableMonths[0]
        }()

        let filteredPayments = filteredPaymentsBase.filter {
            let monthStart = calendar.dateInterval(of: .month, for: $0.payment.date)?.start ?? $0.payment.date
            return calendar.isDate(monthStart, equalTo: syncedMonth, toGranularity: .month)
        }

        let grouped = Dictionary(grouping: filteredPayments) { item in
            calendar.dateInterval(of: .month, for: item.payment.date)?.start ?? item.payment.date
        }

        let groupedByMonth = grouped
            .map { monthStart, items in
                HistoryMonthSection(
                    monthStart: monthStart,
                    items: items.sorted { lhs, rhs in
                        if lhs.payment.date == rhs.payment.date {
                            return sortOrder == .newestFirst
                                ? lhs.service.name < rhs.service.name
                                : lhs.service.name > rhs.service.name
                        }
                        return sortOrder == .newestFirst
                            ? lhs.payment.date > rhs.payment.date
                            : lhs.payment.date < rhs.payment.date
                    },
                    total: items.reduce(0) { $0 + $1.payment.amount }
                )
            }
            .sorted {
                sortOrder == .newestFirst
                    ? $0.monthStart > $1.monthStart
                    : $0.monthStart < $1.monthStart
            }

        return HistoryListData(
            allPayments: allPayments,
            filteredPaymentsBase: filteredPaymentsBase,
            filteredPayments: filteredPayments,
            availableMonths: availableMonths,
            groupedByMonth: groupedByMonth
        )
    }
}
