import Foundation
import SwiftData
import SwiftUI
import UIKit

struct AnalyticsViewData {
    let chartTitle: String
    let comparisonText: String
    let isComparisonPositive: Bool
    let selectedPeriodTotal: Int
    let chartDisplaySummaries: [AnalyticsView.ChartSegmentSummary]
    let allServiceRankings: [AnalyticsView.ServiceSummary]
    let topFiveRankings: [AnalyticsView.ServiceSummary]
    let maxRankingTotal: Int
    let monthlyTrendData: [AnalyticsView.MonthlyTotal]
    let trendCaption: String
    let serviceColorMap: [PersistentIdentifier: Color]
    let otherSegmentColor: Color

    func color(for service: Service, fallback: Color) -> Color {
        serviceColorMap[service.persistentModelID] ?? fallback
    }

    func color(for segment: AnalyticsView.ChartSegmentSummary, fallback: Color) -> Color {
        if segment.isOther {
            return otherSegmentColor
        }

        guard let service = segment.service else {
            return fallback
        }

        return color(for: service, fallback: fallback)
    }
}

enum AnalyticsViewDataBuilder {
    static func make(
        services: [Service],
        period: AnalyticsView.Period,
        selectedMonthDate: Date,
        selectedYear: Int,
        theme: AppTheme,
        calendar: Calendar = .current
    ) -> AnalyticsViewData {
        let allPayments = services
            .flatMap(\.payments)
            .sorted { $0.date > $1.date }

        let periodFilteredPayments = filteredPayments(
            from: allPayments,
            period: period,
            selectedMonthDate: selectedMonthDate,
            selectedYear: selectedYear,
            calendar: calendar
        )

        let selectedPeriodTotal = periodFilteredPayments.reduce(0) { $0 + $1.amount }
        let previousPeriodTotal = previousPeriodTotal(
            from: allPayments,
            period: period,
            selectedMonthDate: selectedMonthDate,
            selectedYear: selectedYear,
            calendar: calendar
        )
        let comparisonText = comparisonText(
            period: period,
            selectedTotal: selectedPeriodTotal,
            previousTotal: previousPeriodTotal
        )
        let allServiceRankings = serviceRankings(from: services, payments: periodFilteredPayments)
        let chartDisplaySummaries = chartDisplaySummaries(from: allServiceRankings)
        let serviceColorMap = serviceColorMap(for: services, theme: theme)
        let monthlyTrendData = trendData(
            from: periodFilteredPayments,
            period: period,
            selectedMonthDate: selectedMonthDate,
            selectedYear: selectedYear,
            calendar: calendar
        )

        return AnalyticsViewData(
            chartTitle: chartTitle(period: period, selectedMonthDate: selectedMonthDate, selectedYear: selectedYear),
            comparisonText: comparisonText,
            isComparisonPositive: previousPeriodTotal <= selectedPeriodTotal,
            selectedPeriodTotal: selectedPeriodTotal,
            chartDisplaySummaries: chartDisplaySummaries,
            allServiceRankings: allServiceRankings,
            topFiveRankings: Array(allServiceRankings.prefix(5)),
            maxRankingTotal: max(allServiceRankings.prefix(5).map(\.total).max() ?? 0, 1),
            monthlyTrendData: monthlyTrendData,
            trendCaption: trendCaption(period: period, selectedYear: selectedYear),
            serviceColorMap: serviceColorMap,
            otherSegmentColor: otherSegmentColor(theme: theme)
        )
    }

    static func makeAxisLabel(for date: Date, period: AnalyticsView.Period) -> String {
        axisLabel(for: date, period: period)
    }
}

private extension AnalyticsViewDataBuilder {
    static func filteredPayments(
        from payments: [Payment],
        period: AnalyticsView.Period,
        selectedMonthDate: Date,
        selectedYear: Int,
        calendar: Calendar
    ) -> [Payment] {
        switch period {
        case .thisMonth:
            let interval = calendar.dateInterval(of: .month, for: selectedMonthDate) ?? DateInterval(start: selectedMonthDate, duration: 1)
            return payments.filter { interval.contains($0.date) }
        case .thisYear:
            let yearDate = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? .now
            let interval = calendar.dateInterval(of: .year, for: yearDate) ?? DateInterval(start: yearDate, duration: 1)
            return payments.filter { interval.contains($0.date) }
        }
    }

    static func previousPeriodTotal(
        from payments: [Payment],
        period: AnalyticsView.Period,
        selectedMonthDate: Date,
        selectedYear: Int,
        calendar: Calendar
    ) -> Int {
        switch period {
        case .thisMonth:
            guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonthDate) else {
                return 0
            }
            let interval = calendar.dateInterval(of: .month, for: previousMonth) ?? DateInterval(start: previousMonth, duration: 1)
            return payments
                .filter { interval.contains($0.date) }
                .reduce(0) { $0 + $1.amount }
        case .thisYear:
            let previousYearDate = calendar.date(from: DateComponents(year: selectedYear - 1, month: 1, day: 1)) ?? .now
            let interval = calendar.dateInterval(of: .year, for: previousYearDate) ?? DateInterval(start: previousYearDate, duration: 1)
            return payments
                .filter { interval.contains($0.date) }
                .reduce(0) { $0 + $1.amount }
        }
    }

    static func comparisonText(period: AnalyticsView.Period, selectedTotal: Int, previousTotal: Int) -> String {
        let delta = selectedTotal - previousTotal

        if previousTotal == 0 {
            if selectedTotal == 0 {
                return period == .thisMonth ? "前月比 ±¥0" : "前年比 ±¥0"
            }
            return period == .thisMonth
                ? "前月比 +¥\(selectedTotal.formatted())"
                : "前年比 +¥\(selectedTotal.formatted())"
        }

        let ratio = Double(delta) / Double(previousTotal)
        let sign = delta >= 0 ? "+" : "-"
        let percent = abs(ratio) * 100
        let prefix = period == .thisMonth ? "前月比" : "前年比"
        return "\(prefix) \(sign)¥\(abs(delta).formatted()) (\(percent.formatted(.number.precision(.fractionLength(1))))%)"
    }

    static func chartTitle(
        period: AnalyticsView.Period,
        selectedMonthDate: Date,
        selectedYear: Int
    ) -> String {
        switch period {
        case .thisMonth:
            return monthOptionTitle(for: selectedMonthDate)
        case .thisYear:
            return "\(selectedYear)年"
        }
    }

    static func trendCaption(period: AnalyticsView.Period, selectedYear: Int) -> String {
        switch period {
        case .thisMonth:
            return "今月の週別支払額推移"
        case .thisYear:
            return "\(selectedYear)年を基準にした年別支払額推移"
        }
    }

    static func monthOptionTitle(for date: Date) -> String {
        date.formatted(
            .dateTime
                .year()
                .month(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
    }

    private static let monthDayAxisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let yearAxisFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy年"
        return formatter
    }()

    static func axisLabel(for date: Date, period: AnalyticsView.Period) -> String {
        switch period {
        case .thisMonth:
            return monthDayAxisFormatter.string(from: date)
        case .thisYear:
            return yearAxisFormatter.string(from: date)
        }
    }

    static func serviceRankings(from services: [Service], payments: [Payment]) -> [AnalyticsView.ServiceSummary] {
        let totalsByServiceID = Dictionary(grouping: payments, by: \.service.persistentModelID)

        return services
            .compactMap { service -> AnalyticsView.ServiceSummary? in
                let total = totalsByServiceID[service.persistentModelID, default: []].reduce(0) { $0 + $1.amount }
                guard total > 0 else { return nil }
                return AnalyticsView.ServiceSummary(service: service, total: total)
            }
            .sorted { lhs, rhs in
                if lhs.total == rhs.total {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.total > rhs.total
            }
    }

    static func chartDisplaySummaries(from summaries: [AnalyticsView.ServiceSummary]) -> [AnalyticsView.ChartSegmentSummary] {
        guard summaries.count > 5 else {
            return summaries.map { item in
                AnalyticsView.ChartSegmentSummary(
                    id: String(describing: item.id),
                    label: item.service.name,
                    total: item.total,
                    service: item.service,
                    isOther: false
                )
            }
        }

        let topFive = summaries.prefix(5).map { item in
            AnalyticsView.ChartSegmentSummary(
                id: String(describing: item.id),
                label: item.service.name,
                total: item.total,
                service: item.service,
                isOther: false
            )
        }
        let otherTotal = summaries.dropFirst(5).reduce(0) { $0 + $1.total }

        guard otherTotal > 0 else { return topFive }

        return topFive + [
            AnalyticsView.ChartSegmentSummary(
                id: "other",
                label: "その他",
                total: otherTotal,
                service: nil,
                isOther: true
            )
        ]
    }

    static func trendData(
        from payments: [Payment],
        period: AnalyticsView.Period,
        selectedMonthDate: Date,
        selectedYear: Int,
        calendar: Calendar
    ) -> [AnalyticsView.MonthlyTotal] {
        switch period {
        case .thisMonth:
            let interval = calendar.dateInterval(of: .month, for: selectedMonthDate) ?? DateInterval(start: selectedMonthDate, duration: 1)
            let weekStarts = stride(from: 0, to: 5, by: 1).compactMap { offset in
                calendar.date(byAdding: .weekOfMonth, value: offset, to: interval.start)
            }

            return weekStarts.map { weekStart in
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                let total = payments
                    .filter { $0.date >= weekStart && $0.date < weekEnd }
                    .reduce(0) { $0 + $1.amount }
                return AnalyticsView.MonthlyTotal(monthStart: weekStart, total: total)
            }
        case .thisYear:
            let yearStarts = (0..<6).compactMap { offset in
                calendar.date(from: DateComponents(year: selectedYear - 5 + offset, month: 1, day: 1))
            }

            return yearStarts.map { yearStart in
                let interval = calendar.dateInterval(of: .year, for: yearStart) ?? DateInterval(start: yearStart, duration: 1)
                let total = payments
                    .filter { interval.contains($0.date) }
                    .reduce(0) { $0 + $1.amount }
                return AnalyticsView.MonthlyTotal(monthStart: yearStart, total: total)
            }
        }
    }

    static func serviceColorMap(for services: [Service], theme: AppTheme) -> [PersistentIdentifier: Color] {
        let orderedServices = services.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        let palette = chartPalette(for: theme, count: orderedServices.count)

        return Dictionary(uniqueKeysWithValues: orderedServices.enumerated().map { index, service in
            (service.persistentModelID, palette[index])
        })
    }

    static func otherSegmentColor(theme: AppTheme) -> Color {
        let components = theme.primaryLight.hsbComponents
        return Color(
            hue: components.hue,
            saturation: max(components.saturation * 0.18, 0.04),
            brightness: min(max(components.brightness * 0.94, 0.78), 0.92)
        )
        .opacity(0.72)
    }

    // Keep the palette anchored to the current theme while softening saturation
    // and gradually lightening lower-ranked segments for a calmer overall tone.
    static func chartPalette(for theme: AppTheme, count: Int) -> [Color] {
        guard count > 0 else { return [] }

        let baseComponents = theme.primary.hsbComponents
        let secondaryComponents = theme.primaryDark.hsbComponents
        let baseHue = baseComponents.hue
        let baseSaturation = min(max(baseComponents.saturation * 0.78, secondaryComponents.saturation * 0.72), 0.72)
        let baseBrightness = min(max(baseComponents.brightness * 1.04, secondaryComponents.brightness * 1.08), 0.9)

        return (0..<count).map { index in
            if index == 0 {
                return Color(
                    hue: baseHue,
                    saturation: min(max(baseSaturation * 1.04, 0.58), 0.7),
                    brightness: min(max(baseBrightness * 0.98, 0.8), 0.88)
                )
            }

            let step = (index + 1) / 2
            let direction = index.isMultiple(of: 2) ? 1.0 : -1.0
            let hueStride = min(0.03 * Double(step), 0.14)
            let hue = normalizedHue(baseHue + (direction * hueStride))

            let saturationDrop = 0.028 * Double(index)
            let saturationLift = 0.008 * Double((index - 1) % 2)
            let saturation = min(
                max(baseSaturation - saturationDrop + saturationLift, 0.34),
                0.64
            )

            let brightnessLift = 0.022 * Double(index)
            let brightnessDrop = 0.01 * Double(index / 4)
            let brightness = min(
                max(baseBrightness + brightnessLift - brightnessDrop, 0.8),
                0.94
            )

            return Color(hue: hue, saturation: saturation, brightness: brightness)
        }
    }

    static func normalizedHue(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 1)
        return remainder >= 0 ? remainder : remainder + 1
    }
}

private extension Color {
    var hsbComponents: (hue: Double, saturation: Double, brightness: Double) {
        let uiColor = UIColor(self)
        var hue: CGFloat = 0
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        var alpha: CGFloat = 0

        if uiColor.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha) {
            return (Double(hue), Double(saturation), Double(brightness))
        }

        var white: CGFloat = 0
        if uiColor.getWhite(&white, alpha: &alpha) {
            return (0, 0, Double(white))
        }

        return (0, 0, 0.5)
    }
}
