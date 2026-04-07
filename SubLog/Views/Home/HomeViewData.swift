import Foundation
import SwiftData
import SwiftUI

struct HomeActiveSubscriptionItem: Identifiable {
    let service: Service
    let subscription: Subscription
    let nextRenewalDate: Date
    let daysUntilRenewal: Int

    var id: PersistentIdentifier { subscription.persistentModelID }

    var nextRenewalDateText: String {
        Self.renewalDateFormatter.string(from: nextRenewalDate)
    }

    var badgeTitle: String {
        if daysUntilRenewal <= 0 {
            return "今日"
        }
        return "あと\(daysUntilRenewal)日"
    }

    var badgeBackgroundColor: Color {
        if daysUntilRenewal <= 3 {
            return Color(red: 1.0, green: 0.91, blue: 0.91)
        } else if daysUntilRenewal <= 10 {
            return Color(red: 1.0, green: 0.94, blue: 0.86)
        } else {
            return Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }

    var badgeForegroundColor: Color {
        if daysUntilRenewal <= 3 {
            return Color(red: 0.82, green: 0.28, blue: 0.28)
        } else if daysUntilRenewal <= 10 {
            return Color(red: 0.82, green: 0.49, blue: 0.12)
        } else {
            return Color(red: 0.43, green: 0.45, blue: 0.52)
        }
    }
}

private extension HomeActiveSubscriptionItem {
    static let renewalDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
    }()
}

struct HomeMonthlyExpense: Identifiable {
    let monthStart: Date
    let total: Int
    let isCurrentMonth: Bool

    var id: Date { monthStart }

    var monthLabel: String {
        "\(Calendar.current.component(.month, from: monthStart))月"
    }
}

struct HomeDashboardData {
    let monthlyTotal: Int
    let previousMonthTotal: Int
    let recentMonthlyExpenses: [HomeMonthlyExpense]
    let activeSubscriptions: [HomeActiveSubscriptionItem]

    var monthComparisonText: String {
        let difference = monthlyTotal - previousMonthTotal

        if previousMonthTotal == 0 {
            if monthlyTotal == 0 {
                return "前月比 ±0円"
            }
            return "前月比 +\(difference.formatted(.number.grouping(.automatic)))円"
        }

        let sign = difference >= 0 ? "+" : "-"
        return "前月比 \(sign)\(abs(difference).formatted(.number.grouping(.automatic)))円"
    }

    var maxMonthlyExpense: Double {
        max(Double(recentMonthlyExpenses.map(\.total).max() ?? 0), 1)
    }
}

enum HomeDashboardBuilder {
    static func make(services: [Service], calendar: Calendar = .current) -> HomeDashboardData {
        let allPayments = services.flatMap(\.payments)
        let currentMonthInterval = calendar.dateInterval(of: .month, for: .now) ?? DateInterval(start: .now, duration: 1)
        let previousDate = calendar.date(byAdding: .month, value: -1, to: .now) ?? .now
        let previousMonthInterval = calendar.dateInterval(of: .month, for: previousDate) ?? DateInterval(start: previousDate, duration: 1)

        let monthlyTotal = allPayments
            .filter { currentMonthInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }

        let previousMonthTotal = allPayments
            .filter { previousMonthInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }

        let recentMonthlyExpenses = makeRecentMonthlyExpenses(
            from: allPayments,
            currentMonthStart: currentMonthInterval.start,
            calendar: calendar
        )

        let activeSubscriptions = makeActiveSubscriptions(from: services, calendar: calendar)

        return HomeDashboardData(
            monthlyTotal: monthlyTotal,
            previousMonthTotal: previousMonthTotal,
            recentMonthlyExpenses: recentMonthlyExpenses,
            activeSubscriptions: activeSubscriptions
        )
    }
}

private extension HomeDashboardBuilder {
    static func makeRecentMonthlyExpenses(
        from payments: [Payment],
        currentMonthStart: Date,
        calendar: Calendar
    ) -> [HomeMonthlyExpense] {
        (-5...0).compactMap { offset in
            guard let monthStart = calendar.date(byAdding: .month, value: offset, to: currentMonthStart),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                return nil
            }

            let total = payments
                .filter { monthInterval.contains($0.date) }
                .reduce(0) { $0 + $1.amount }

            return HomeMonthlyExpense(
                monthStart: monthStart,
                total: total,
                isCurrentMonth: calendar.isDate(monthStart, equalTo: currentMonthStart, toGranularity: .month)
            )
        }
    }

    static func makeActiveSubscriptions(
        from services: [Service],
        calendar: Calendar
    ) -> [HomeActiveSubscriptionItem] {
        services
            .filter { !$0.isArchived }
            .flatMap { service in
                service.subscriptions.compactMap { subscription in
                    guard subscription.isActive else { return nil }
                    let nextDate = nextRenewalDate(for: subscription, calendar: calendar)

                    return HomeActiveSubscriptionItem(
                        service: service,
                        subscription: subscription,
                        nextRenewalDate: nextDate,
                        daysUntilRenewal: daysUntilRenewal(from: nextDate, calendar: calendar)
                    )
                }
            }
            .sorted { lhs, rhs in
                if lhs.nextRenewalDate == rhs.nextRenewalDate {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.nextRenewalDate < rhs.nextRenewalDate
            }
            .prefix(5)
            .map { $0 }
    }

    static func nextRenewalDate(for subscription: Subscription, calendar: Calendar) -> Date {
        let component = subscription.renewalInterval.unit.calendarComponent
        var candidate = subscription.startDate

        while candidate < .now {
            candidate = calendar.date(
                byAdding: component,
                value: subscription.renewalInterval.value,
                to: candidate
            ) ?? candidate
        }

        return candidate
    }

    static func daysUntilRenewal(from nextRenewalDate: Date, calendar: Calendar) -> Int {
        calendar.dateComponents([.day], from: .now, to: nextRenewalDate).day ?? 0
    }
}
