import Foundation
import SwiftData

struct ServiceDetailPaymentRowData: Identifiable {
    let id: PersistentIdentifier
    let payment: Payment
    let formattedDate: String
}

struct ServiceDetailViewData {
    let totalAmount: Int
    let focusedPeriodAmount: Int
    let focusedPeriodTitle: String
    let paymentCount: Int
    let paymentRows: [ServiceDetailPaymentRowData]
    let isPaymentHistoryEmpty: Bool
}

enum ServiceDetailViewDataBuilder {
    static func build(
        service: Service,
        summaryScope: ServiceDetailView.SummaryScope,
        calendar: Calendar = .current
    ) -> ServiceDetailViewData {
        let sortedPayments = service.payments.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.type < rhs.type
            }
            return lhs.date > rhs.date
        }

        return ServiceDetailViewData(
            totalAmount: service.payments.reduce(0) { $0 + $1.amount },
            focusedPeriodAmount: focusedPeriodAmount(for: service, summaryScope: summaryScope, calendar: calendar),
            focusedPeriodTitle: focusedPeriodTitle(for: summaryScope),
            paymentCount: service.payments.count,
            paymentRows: sortedPayments.map { payment in
                ServiceDetailPaymentRowData(
                    id: payment.persistentModelID,
                    payment: payment,
                    formattedDate: payment.date.formatted(historyDateFormat)
                )
            },
            isPaymentHistoryEmpty: sortedPayments.isEmpty
        )
    }

    private static func focusedPeriodAmount(
        for service: Service,
        summaryScope: ServiceDetailView.SummaryScope,
        calendar: Calendar
    ) -> Int {
        switch summaryScope {
        case .currentMonth:
            return service.payments
                .filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
        case let .analyticsMonth(date):
            return service.payments
                .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
        case let .analyticsYear(year):
            return service.payments
                .filter { calendar.component(.year, from: $0.date) == year }
                .reduce(0) { $0 + $1.amount }
        }
    }

    private static func focusedPeriodTitle(for summaryScope: ServiceDetailView.SummaryScope) -> String {
        switch summaryScope {
        case .currentMonth, .analyticsMonth:
            return "今月の支払額"
        case .analyticsYear:
            return "今年の支払額"
        }
    }

    private static var historyDateFormat: Date.FormatStyle {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
    }
}
