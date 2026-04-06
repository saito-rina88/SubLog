import Charts
import SwiftData
import SwiftUI
import UIKit

struct AnalyticsView: View {
    enum Period: String, CaseIterable, Identifiable {
        case thisMonth
        case thisYear

        var id: Self { self }

        var title: String {
            switch self {
            case .thisMonth:
                return "月"
            case .thisYear:
                return "年"
            }
        }
    }

    struct ServiceSummary: Identifiable {
        let service: Service
        let total: Int

        var id: PersistentIdentifier { service.persistentModelID }
    }

    struct ChartSegmentSummary: Identifiable {
        let id: String
        let label: String
        let total: Int
        let service: Service?
        let isOther: Bool
    }

    struct MonthlyTotal: Identifiable {
        let monthStart: Date
        let total: Int

        var id: Date { monthStart }
    }

    @Query private var services: [Service]
    @EnvironmentObject private var theme: ThemeManager

    @State private var selectedPeriod: Period = .thisMonth
    @State private var selectedMonthDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    @State private var selectedYear = Calendar.current.component(.year, from: .now)
    @State private var showFullRanking = false
    @State private var showMonthPicker = false
    @State private var showYearPicker = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    periodCard
                    monthlyServiceChartCard
                    rankingCard
                    trendChartCard
                }
                .padding(20)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .sheet(isPresented: $showFullRanking) {
                AnalyticsRankingListView(rankings: allServiceRankings, summaryScope: detailSummaryScope)
                    .environmentObject(theme)
            }
            .sheet(isPresented: $showMonthPicker) {
                AnalyticsMonthPickerSheet(selectedMonthDate: $selectedMonthDate)
                    .environmentObject(theme)
                    .presentationDetents([.height(320)])
            }
            .sheet(isPresented: $showYearPicker) {
                AnalyticsYearPickerSheet(selectedYear: $selectedYear)
                    .environmentObject(theme)
                    .presentationDetents([.height(320)])
            }
        }
    }
}

private extension AnalyticsView {
    var allPayments: [Payment] {
        services
            .flatMap(\.payments)
            .sorted { $0.date > $1.date }
    }

    var periodFilteredPayments: [Payment] {
        let calendar = Calendar.current

        switch selectedPeriod {
        case .thisMonth:
            let interval = calendar.dateInterval(of: .month, for: selectedMonthDate) ?? DateInterval(start: selectedMonthDate, duration: 1)
            return allPayments.filter { interval.contains($0.date) }
        case .thisYear:
            let yearDate = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? .now
            let interval = calendar.dateInterval(of: .year, for: yearDate) ?? DateInterval(start: yearDate, duration: 1)
            return allPayments.filter { interval.contains($0.date) }
        }
    }

    var currentMonth: Date {
        Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: .now)) ?? .now
    }

    var chartTitle: String {
        switch selectedPeriod {
        case .thisMonth:
            return selectedMonthTitle
        case .thisYear:
            return "\(String(selectedYear))年"
        }
    }

    var selectedMonthTotal: Int {
        periodFilteredPayments.reduce(0) { $0 + $1.amount }
    }

    var previousMonthTotal: Int {
        let calendar = Calendar.current
        guard let previousMonth = calendar.date(byAdding: .month, value: -1, to: selectedMonthDate) else {
            return 0
        }
        let interval = calendar.dateInterval(of: .month, for: previousMonth) ?? DateInterval(start: previousMonth, duration: 1)
        return allPayments
            .filter { interval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var selectedYearTotal: Int {
        periodFilteredPayments.reduce(0) { $0 + $1.amount }
    }

    var selectedPeriodTotal: Int {
        switch selectedPeriod {
        case .thisMonth:
            return selectedMonthTotal
        case .thisYear:
            return selectedYearTotal
        }
    }

    var previousYearTotal: Int {
        let calendar = Calendar.current
        let previousYearDate = calendar.date(from: DateComponents(year: selectedYear - 1, month: 1, day: 1)) ?? .now
        let interval = calendar.dateInterval(of: .year, for: previousYearDate) ?? DateInterval(start: previousYearDate, duration: 1)
        return allPayments
            .filter { interval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthOverMonthText: String {
        let delta = selectedMonthTotal - previousMonthTotal

        if previousMonthTotal == 0 {
            if selectedMonthTotal == 0 {
                return "前月比 ±¥0"
            }
            return "前月比 +¥\(selectedMonthTotal.formatted())"
        }

        let ratio = Double(delta) / Double(previousMonthTotal)
        let sign = delta >= 0 ? "+" : "-"
        let percent = abs(ratio) * 100
        return "前月比 \(sign)¥\(abs(delta).formatted()) (\(percent.formatted(.number.precision(.fractionLength(1))))%)"
    }

    var yearOverYearText: String {
        let delta = selectedYearTotal - previousYearTotal

        if previousYearTotal == 0 {
            if selectedYearTotal == 0 {
                return "前年比 ±¥0"
            }
            return "前年比 +¥\(selectedYearTotal.formatted())"
        }

        let ratio = Double(delta) / Double(previousYearTotal)
        let sign = delta >= 0 ? "+" : "-"
        let percent = abs(ratio) * 100
        return "前年比 \(sign)¥\(abs(delta).formatted()) (\(percent.formatted(.number.precision(.fractionLength(1))))%)"
    }

    var selectedMonthTitle: String {
        monthOptionTitle(for: selectedMonthDate)
    }

    var chartServiceSummaries: [ServiceSummary] {
        let totals = Dictionary(grouping: periodFilteredPayments, by: \.service.persistentModelID)
            .compactMap { _, payments -> ServiceSummary? in
                guard let service = payments.first?.service else { return nil }
                let total = payments.reduce(0) { $0 + $1.amount }
                guard total > 0 else { return nil }
                return ServiceSummary(service: service, total: total)
            }
            .sorted { lhs, rhs in
                if lhs.total == rhs.total {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.total > rhs.total
            }

        return totals
    }

    var chartDisplaySummaries: [ChartSegmentSummary] {
        makeChartDisplaySummaries(from: chartServiceSummaries)
    }

    var serviceColorMap: [PersistentIdentifier: Color] {
        let orderedServices = services.sorted { lhs, rhs in
            lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
        }
        let palette = chartPalette(for: theme.current, count: orderedServices.count)

        return Dictionary(uniqueKeysWithValues: orderedServices.enumerated().map { index, service in
            (service.persistentModelID, palette[index])
        })
    }

    func color(for service: Service) -> Color {
        serviceColorMap[service.persistentModelID] ?? theme.current.primary
    }

    var otherSegmentColor: Color {
        let components = theme.current.primaryLight.hsbComponents
        return Color(
            hue: components.hue,
            saturation: max(components.saturation * 0.18, 0.04),
            brightness: min(max(components.brightness * 0.94, 0.78), 0.92)
        )
        .opacity(0.72)
    }

    func color(for segment: ChartSegmentSummary) -> Color {
        if segment.isOther {
            return otherSegmentColor
        }

        guard let service = segment.service else {
            return theme.current.primary
        }

        return color(for: service)
    }

    // Keep the palette anchored to the current theme while softening saturation
    // and gradually lightening lower-ranked segments for a calmer overall tone.
    func chartPalette(for theme: AppTheme, count: Int) -> [Color] {
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

    func normalizedHue(_ value: Double) -> Double {
        let remainder = value.truncatingRemainder(dividingBy: 1)
        return remainder >= 0 ? remainder : remainder + 1
    }

    func makeChartDisplaySummaries(from summaries: [ServiceSummary]) -> [ChartSegmentSummary] {
        guard summaries.count > 5 else {
            return summaries.map { item in
                ChartSegmentSummary(
                    id: String(describing: item.id),
                    label: item.service.name,
                    total: item.total,
                    service: item.service,
                    isOther: false
                )
            }
        }

        let topFive = summaries.prefix(5).map { item in
            ChartSegmentSummary(
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
            ChartSegmentSummary(
                id: "other",
                label: "その他",
                total: otherTotal,
                service: nil,
                isOther: true
            )
        ]
    }

    var allServiceRankings: [ServiceSummary] {
        let totalsByServiceID = Dictionary(grouping: periodFilteredPayments, by: \.service.persistentModelID)

        return services
            .compactMap { service -> ServiceSummary? in
                let total = totalsByServiceID[service.persistentModelID, default: []].reduce(0) { $0 + $1.amount }
                guard total > 0 else { return nil }
                return ServiceSummary(service: service, total: total)
            }
            .sorted { lhs, rhs in
                if lhs.total == rhs.total {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.total > rhs.total
            }
    }

    var topFiveRankings: [ServiceSummary] {
        Array(allServiceRankings.prefix(5))
    }

    var detailSummaryScope: ServiceDetailView.SummaryScope {
        switch selectedPeriod {
        case .thisMonth:
            return .analyticsMonth(selectedMonthDate)
        case .thisYear:
            return .analyticsYear(selectedYear)
        }
    }

    var maxRankingTotal: Int {
        max(topFiveRankings.map(\.total).max() ?? 0, 1)
    }

    var monthlyTrendData: [MonthlyTotal] {
        let calendar = Calendar.current
        switch selectedPeriod {
        case .thisMonth:
            let interval = calendar.dateInterval(of: .month, for: selectedMonthDate) ?? DateInterval(start: selectedMonthDate, duration: 1)
            let payments = periodFilteredPayments
            let weekStarts = stride(from: 0, to: 5, by: 1).compactMap { offset in
                calendar.date(byAdding: .weekOfMonth, value: offset, to: interval.start)
            }

            return weekStarts.map { weekStart in
                let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? weekStart
                let total = payments
                    .filter { $0.date >= weekStart && $0.date < weekEnd }
                    .reduce(0) { $0 + $1.amount }
                return MonthlyTotal(monthStart: weekStart, total: total)
            }
        case .thisYear:
            let yearStart = calendar.date(from: DateComponents(year: selectedYear, month: 1, day: 1)) ?? currentMonth
            let months = (0..<12).compactMap { offset in
                calendar.date(byAdding: .month, value: offset, to: yearStart)
            }

            return months.map { month in
                let interval = calendar.dateInterval(of: .month, for: month) ?? DateInterval(start: month, duration: 1)
                let total = periodFilteredPayments
                    .filter { interval.contains($0.date) }
                    .reduce(0) { $0 + $1.amount }
                return MonthlyTotal(monthStart: month, total: total)
            }
        }
    }

    var periodCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Picker("期間", selection: $selectedPeriod) {
                    ForEach(Period.allCases) { period in
                        Text(period.title).tag(period)
                    }
                }
                .pickerStyle(.segmented)
                .tint(theme.current.primary)

                if selectedPeriod == .thisMonth {
                    HStack {
                        Button {
                            moveMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                        }

                        Spacer()

                        Button {
                            showMonthPicker = true
                        } label: {
                            Text(selectedMonthTitle)
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            moveMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.secondary)
                } else {
                    HStack {
                        Button {
                            selectedYear -= 1
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.headline)
                        }

                        Spacer()

                        Button {
                            showYearPicker = true
                        } label: {
                            Text(String(selectedYear) + "年")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            selectedYear += 1
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.headline)
                        }
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }
    }

    var monthlyServiceChartCard: some View {
        card {
            VStack(alignment: .leading, spacing: 14) {
                Text(chartTitle)
                    .font(.headline)

                if selectedPeriod == .thisMonth {
                    Text(monthOverMonthText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(previousMonthTotal <= selectedMonthTotal ? theme.current.primary : .secondary)
                } else {
                    Text(yearOverYearText)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(previousYearTotal <= selectedYearTotal ? theme.current.primary : .secondary)
                }

                if chartDisplaySummaries.isEmpty {
                    Text("この期間の支払いデータはありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ZStack {
                            Chart(chartDisplaySummaries) { item in
                                SectorMark(
                                    angle: .value("支払額", item.total),
                                    innerRadius: .ratio(0.58),
                                    angularInset: 2
                                )
                                .foregroundStyle(color(for: item))
                            }
                            .frame(height: 240)

                            VStack(spacing: 4) {
                                Text("合計")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(selectedPeriodTotal, format: .currency(code: "JPY"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(theme.current.primaryDeep)
                            }
                        }

                        ForEach(chartDisplaySummaries) { item in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(color(for: item))
                                    .frame(width: 10, height: 10)

                                Text(item.label)
                                    .font(.subheadline)

                                Spacer()

                                Text(item.total, format: .currency(code: "JPY"))
                                    .font(.subheadline.weight(.semibold))
                            }
                        }
                    }
                }
            }
        }
    }

    var rankingCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("ランキング")
                        .font(.headline)

                    Spacer()

                    Button("すべて見る >") {
                        showFullRanking = true
                    }
                    .font(.subheadline.weight(.semibold))
                }

                if topFiveRankings.isEmpty {
                    Text("ランキング表示に必要な支払いデータがありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(topFiveRankings.enumerated()), id: \.element.id) { index, item in
                        NavigationLink {
                            ServiceDetailView(service: item.service, summaryScope: detailSummaryScope)
                                .environmentObject(theme)
                        } label: {
                            HStack(spacing: 12) {
                                rankBadge(index + 1)
                                ServiceIconView(service: item.service, size: 44)

                                VStack(alignment: .leading, spacing: 6) {
                                    Text(item.service.name)
                                        .font(.subheadline.weight(.bold))
                                        .foregroundStyle(.primary)

                                    GeometryReader { proxy in
                                        let width = proxy.size.width * CGFloat(item.total) / CGFloat(maxRankingTotal)

                                        ZStack(alignment: .leading) {
                                            Capsule()
                                                .fill(theme.current.primaryXLight)
                                            Capsule()
                                                .fill(theme.current.primaryMid)
                                                .frame(width: max(8, width))
                                        }
                                    }
                                    .frame(height: 8)
                                }

                                Spacer()

                                Text(item.total, format: .currency(code: "JPY"))
                                    .font(.subheadline.weight(.bold))
                                    .foregroundStyle(.primary)
                            }
                            .padding(.vertical, 4)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    var trendChartCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("推移グラフ")
                    .font(.headline)

                if monthlyTrendData.allSatisfy({ $0.total == 0 }) {
                    Text("推移グラフに必要な支払いデータがありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(monthlyTrendData) { item in
                        AreaMark(
                            x: .value("期間", item.monthStart),
                            y: .value("支払額", item.total)
                        )
                        .foregroundStyle(theme.current.primary.opacity(0.18))
                        .interpolationMethod(.catmullRom)

                        LineMark(
                            x: .value("期間", item.monthStart),
                            y: .value("支払額", item.total)
                        )
                        .foregroundStyle(theme.current.primary)
                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("期間", item.monthStart),
                            y: .value("支払額", item.total)
                        )
                        .foregroundStyle(theme.current.primaryDark)
                    }
                    .frame(height: 220)
                    .chartXAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(axisLabel(for: date))
                                }
                            }
                        }
                    }

                    HStack {
                        Text(trendCaption)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Spacer()
                    }
                }
            }
        }
    }

    func card<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        content()
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
            )
    }

    func rankBadge(_ rank: Int) -> some View {
        Text("\(rank)")
            .font(.caption.weight(.bold))
            .foregroundStyle(.white)
            .frame(width: 24, height: 24)
            .background(
                Circle()
                    .fill(theme.current.primary)
            )
    }

    func axisLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        switch selectedPeriod {
        case .thisMonth:
            formatter.dateFormat = "M/d"
        case .thisYear:
            formatter.dateFormat = "M月"
        }

        return formatter.string(from: date)
    }

    var trendCaption: String {
        switch selectedPeriod {
        case .thisMonth:
            return "今月の週別支払額推移"
        case .thisYear:
            return "\(String(selectedYear))年の月別支払額推移"
        }
    }

    func moveMonth(by offset: Int) {
        guard let nextMonth = Calendar.current.date(byAdding: .month, value: offset, to: selectedMonthDate) else { return }
        selectedMonthDate = Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: nextMonth)) ?? nextMonth
    }

    func monthOptionTitle(for date: Date) -> String {
        date.formatted(
            .dateTime
                .year()
                .month(.wide)
                .locale(Locale(identifier: "ja_JP"))
        )
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

private struct AnalyticsMonthPickerSheet: View {
    @Binding var selectedMonthDate: Date

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @State private var selectedYear: Int
    @State private var selectedMonth: Int

    init(selectedMonthDate: Binding<Date>) {
        _selectedMonthDate = selectedMonthDate
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: selectedMonthDate.wrappedValue)
        _selectedYear = State(initialValue: components.year ?? calendar.component(.year, from: .now))
        _selectedMonth = State(initialValue: components.month ?? calendar.component(.month, from: .now))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                HStack(spacing: 0) {
                    Picker("年", selection: $selectedYear) {
                        ForEach(yearOptions, id: \.self) { year in
                            Text(String(year) + "年").tag(year)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()

                    Picker("月", selection: $selectedMonth) {
                        ForEach(1...12, id: \.self) { month in
                            Text(String(month) + "月").tag(month)
                        }
                    }
                    .pickerStyle(.wheel)
                    .labelsHidden()
                }
                .onChange(of: selectedYear) { _, _ in updateSelectedMonthDate() }
                .onChange(of: selectedMonth) { _, _ in updateSelectedMonthDate() }
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("年月を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var yearOptions: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((currentYear - 10)...(currentYear + 10))
    }

    private func updateSelectedMonthDate() {
        let calendar = Calendar.current
        let components = DateComponents(year: selectedYear, month: selectedMonth, day: 1)
        selectedMonthDate = calendar.date(from: components) ?? selectedMonthDate
    }
}

private struct AnalyticsYearPickerSheet: View {
    @Binding var selectedYear: Int

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager

    private var years: [Int] {
        let currentYear = Calendar.current.component(.year, from: .now)
        return Array((currentYear - 10)...(currentYear + 10))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Picker("", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text(String(year) + "年").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .labelsHidden()
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("年を選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("完了") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct AnalyticsRankingListView: View {
    let rankings: [AnalyticsView.ServiceSummary]
    let summaryScope: ServiceDetailView.SummaryScope

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager

    var body: some View {
        NavigationStack {
            List(Array(rankings.enumerated()), id: \.element.id) { index, item in
                NavigationLink {
                    ServiceDetailView(service: item.service, summaryScope: summaryScope)
                        .environmentObject(theme)
                } label: {
                    HStack(spacing: 12) {
                        Text("\(index + 1)")
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(theme.current.primary)
                            .frame(width: 28)

                        ServiceIconView(service: item.service, size: 40)

                        Text(item.service.name)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.primary)

                        Spacer()

                        Text(item.total, format: .currency(code: "JPY"))
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(.primary)
                    }
                    .padding(.vertical, 4)
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("ランキング")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Service.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    SampleDataFactory.makeServices().forEach {
        container.mainContext.insert($0)
    }

    return AnalyticsView()
        .environmentObject(EntitlementManager())
        .environmentObject(ThemeManager())
        .modelContainer(container)
}
