import Charts
import SwiftData
import SwiftUI

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

    private var analyticsData: AnalyticsViewData {
        AnalyticsViewDataBuilder.make(
            services: services,
            period: selectedPeriod,
            selectedMonthDate: selectedMonthDate,
            selectedYear: selectedYear,
            theme: theme.current
        )
    }

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
                AnalyticsRankingListView(rankings: analyticsData.allServiceRankings, summaryScope: detailSummaryScope)
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
    var detailSummaryScope: ServiceDetailView.SummaryScope {
        switch selectedPeriod {
        case .thisMonth:
            return .analyticsMonth(selectedMonthDate)
        case .thisYear:
            return .analyticsYear(selectedYear)
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
                            Text(monthOptionTitle(for: selectedMonthDate))
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
                Text(analyticsData.chartTitle)
                    .font(.headline)

                Text(analyticsData.comparisonText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(analyticsData.isComparisonPositive ? theme.current.primary : .secondary)

                if analyticsData.chartDisplaySummaries.isEmpty {
                    Text("この期間の支払いデータはありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    VStack(spacing: 12) {
                        ZStack {
                            Chart(analyticsData.chartDisplaySummaries) { item in
                                SectorMark(
                                    angle: .value("支払額", item.total),
                                    innerRadius: .ratio(0.58),
                                    angularInset: 2
                                )
                                .foregroundStyle(analyticsData.color(for: item, fallback: theme.current.primary))
                            }
                            .frame(height: 240)

                            VStack(spacing: 4) {
                                Text("合計")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text(analyticsData.selectedPeriodTotal, format: .currency(code: "JPY"))
                                    .font(.headline.weight(.bold))
                                    .foregroundStyle(theme.current.primaryDeep)
                            }
                        }

                        ForEach(analyticsData.chartDisplaySummaries) { item in
                            HStack(spacing: 10) {
                                Circle()
                                    .fill(analyticsData.color(for: item, fallback: theme.current.primary))
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

                if analyticsData.topFiveRankings.isEmpty {
                    Text("ランキング表示に必要な支払いデータがありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(Array(analyticsData.topFiveRankings.enumerated()), id: \.element.id) { index, item in
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
                                        let width = proxy.size.width * CGFloat(item.total) / CGFloat(analyticsData.maxRankingTotal)

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

                if analyticsData.monthlyTrendData.allSatisfy({ $0.total == 0 }) {
                    Text("推移グラフに必要な支払いデータがありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Chart(analyticsData.monthlyTrendData) { item in
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
                        Text(analyticsData.trendCaption)
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
            formatter.dateFormat = "yyyy年"
        }

        return formatter.string(from: date)
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
