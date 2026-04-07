import SwiftUI
import SwiftData

struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager
    @Query private var services: [Service]

    @State private var searchText = ""
    @State private var selectedFilter: HistoryFilterType = .all
    @State private var selectedTabIndex: Int = 0
    @State private var sortOrder: HistorySortOrder = .newestFirst
    @State private var selectedMonth = Calendar.current.dateInterval(of: .month, for: .now)?.start ?? .now
    @State private var showListMonthPicker = false
    @State private var paymentToEdit: Payment?
    @State private var paymentToDelete: Payment?

    private var listData: HistoryListData {
        HistoryListDataBuilder.make(
            services: services,
            searchText: searchText,
            selectedFilter: selectedFilter,
            selectedMonth: selectedMonth,
            sortOrder: sortOrder
        )
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                tabPicker

                Group {
                    if selectedTabIndex == 0 {
                        listContent
                    } else {
                        calendarContent
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .sheet(item: $paymentToEdit) { payment in
                EditPaymentView(payment: payment)
            }
            .sheet(isPresented: $showListMonthPicker) {
                MonthPickerView(selectedMonth: $selectedMonth, isPresented: $showListMonthPicker)
                    .presentationDetents([.height(280)])
            }
            .alert(MessageCatalog.paymentDeleteTitle, isPresented: deleteAlertBinding) {
                Button("キャンセル", role: .cancel) {
                    paymentToDelete = nil
                }
                Button("削除", role: .destructive) {
                    deleteSelectedPayment()
                }
            } message: {
                Text(MessageCatalog.operationCannotBeUndone)
            }
            .onAppear {
                syncSelectedMonth()
            }
            .onChange(of: selectedFilter) { _, _ in
                syncSelectedMonth()
            }
            .onChange(of: searchText) { _, _ in
                syncSelectedMonth()
            }
        }
    }
}

private extension HistoryView {
    var tabPicker: some View {
        Picker("", selection: $selectedTabIndex) {
            Text("一覧").tag(0)
            Text("カレンダー").tag(1)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.top, 16)
        .padding(.bottom, 8)
    }

    var searchBar: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("サービス名・項目名・メモで検索", text: $searchText)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()

            if !searchText.isEmpty {
                Button {
                    searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(uiColor: .systemBackground))
        )
    }

    @ViewBuilder
    var listContent: some View {
        VStack(spacing: 0) {
            searchBar
                .padding(.horizontal, 16)
                .padding(.bottom, 8)

            filterChips
                .padding(.horizontal, 20)
                .padding(.bottom, 8)

            monthNavigation
                .padding(.horizontal, 20)
                .padding(.top, 0)
                .padding(.bottom, -6)

            listSections
                .padding(.top, 0)
        }
    }

    var listSections: some View {
        List {
            if listData.groupedByMonth.isEmpty {
                Section {
                    Text("該当する履歴はありません。")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.vertical, 8)
                }
            } else {
                ForEach(Array(listData.groupedByMonth.enumerated()), id: \.element.monthStart) { index, section in
                    Section {
                        ForEach(section.items) { item in
                            NavigationLink {
                                destination(for: item)
                            } label: {
                                historyRow(item)
                            }
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button("削除", role: .destructive) {
                                    paymentToDelete = item.payment
                                }
                                .tint(.red)
                            }
                        }

                        if index == listData.groupedByMonth.count - 1 {
                            monthTotalSummary
                                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                .listRowBackground(
                                    UnevenRoundedRectangle(
                                        topLeadingRadius: 0,
                                        bottomLeadingRadius: 20,
                                        bottomTrailingRadius: 20,
                                        topTrailingRadius: 0,
                                        style: .continuous
                                    )
                                    .fill(Color(uiColor: .systemBackground))
                                )
                                .listRowSeparator(.hidden)
                        }
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(theme.current.primaryXLight)
    }

    @ViewBuilder
    var calendarContent: some View {
        HistoryCalendarView(
            payments: listData.allPayments,
            destination: { item in AnyView(destination(for: item)) }
        )
    }

    var filterChips: some View {
        HStack(spacing: 10) {
            ForEach(HistoryFilterType.allCases) { filter in
                Button {
                    selectedFilter = filter
                } label: {
                    Text(filter.rawValue)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(selectedFilter == filter ? .white : theme.current.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            Capsule(style: .continuous)
                                .fill(selectedFilter == filter ? theme.current.primary : .white)
                        )
                }
                .buttonStyle(.plain)
            }

            Spacer()

            Button {
                sortOrder = sortOrder == .newestFirst ? .oldestFirst : .newestFirst
            } label: {
                Image(systemName: "arrow.up.arrow.down")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(theme.current.primary)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(.white)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    var monthNavigation: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 2) {
                Button {
                    moveToPreviousMonth()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(canMoveToPreviousMonth ? Color.secondary : Color.secondary.opacity(0.45))
                .disabled(!canMoveToPreviousMonth)

                Button {
                    showListMonthPicker = true
                } label: {
                    Text(ViewDataCommon.yearMonthString(from: selectedMonth))
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 140, minHeight: 36, alignment: .center)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    moveToNextMonth()
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(canMoveToNextMonth ? Color.secondary : Color.secondary.opacity(0.45))
                .disabled(!canMoveToNextMonth)
            }

            Spacer(minLength: 0)
        }
        .padding(.vertical, 1)
    }

    var monthTotalSummary: some View {
        VStack(spacing: 0) {
            Divider()
                .padding(.bottom, 8)

            HStack(alignment: .firstTextBaseline, spacing: 5) {
                Text("月合計")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(theme.current.primary.opacity(0.72))

                Text(verbatim: currentMonthTotalText)
                    .font(.headline.weight(.bold))
                    .foregroundStyle(theme.current.primary)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.trailing, 12)
        }
        .padding(.top, -8)
        .padding(.bottom, 8)
    }

    var currentMonthTotal: Int {
        listData.currentMonthTotal
    }

    var currentMonthTotalText: String {
        listData.currentMonthTotalText
    }

    func historyRow(_ item: HistoryPaymentWithService) -> some View {
        HStack(spacing: 12) {
            ServiceIconView(service: item.service, size: 44)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.service.name)
                    .font(.subheadline.weight(.bold))
                Text(item.payment.type.replacingOccurrences(of: "、", with: "\n"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(item.payment.amount, format: .currency(code: "JPY"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(theme.current.primary)
                Text(item.payment.date.formatted(historyDateFormat))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }

    @ViewBuilder
    func destination(for item: HistoryPaymentWithService) -> some View {
        switch item.service.serviceType {
        case .game:
            GameChargeDetailView(payment: item.payment)
        case .subscription:
            if let subscription = item.payment.subscription {
                SubscriptionDetailView(subscription: subscription, service: item.service)
            } else {
                GameChargeDetailView(payment: item.payment)
            }
        }
    }

    var calendar: Calendar {
        Calendar.current
    }

    var historyDateFormat: Date.FormatStyle {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
    }

    var deleteAlertBinding: Binding<Bool> {
        Binding(
            get: { paymentToDelete != nil },
            set: { if !$0 { paymentToDelete = nil } }
        )
    }

    func deleteSelectedPayment() {
        guard let paymentToDelete else { return }
        modelContext.delete(paymentToDelete)
        self.paymentToDelete = nil
        syncSelectedMonth()
    }

    var selectedMonthIndex: Int? {
        listData.selectedMonthIndex(for: selectedMonth, calendar: calendar)
    }

    var canMoveToPreviousMonth: Bool {
        guard let selectedMonthIndex else { return false }
        return selectedMonthIndex < listData.availableMonths.count - 1
    }

    var canMoveToNextMonth: Bool {
        guard let selectedMonthIndex else { return false }
        return selectedMonthIndex > 0
    }

    func moveToPreviousMonth() {
        guard let previousMonth = listData.month(before: selectedMonth, calendar: calendar) else { return }
        selectedMonth = previousMonth
    }

    func moveToNextMonth() {
        guard let nextMonth = listData.month(after: selectedMonth, calendar: calendar) else { return }
        selectedMonth = nextMonth
    }

    func syncSelectedMonth() {
        selectedMonth = listData.syncedMonth(from: selectedMonth, calendar: calendar)
    }
}

private struct HistoryCalendarView: View {
    @EnvironmentObject private var theme: ThemeManager

    let payments: [HistoryPaymentWithService]
    let destination: (HistoryPaymentWithService) -> AnyView

    @State private var calendarMonth: Date = .now
    @State private var selectedDate: Date? = .now
    @State private var showMonthPicker = false

    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.firstWeekday = 2
        return calendar
    }

    private let weekdays = ["月", "火", "水", "木", "金", "土", "日"]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                monthNavigation
                calendarCard
                selectedDaySection
            }
            .padding(.bottom, 24)
        }
        .background(theme.current.primaryXLight)
        .sheet(isPresented: $showMonthPicker) {
            MonthPickerView(selectedMonth: $calendarMonth, isPresented: $showMonthPicker)
                .presentationDetents([.medium])
        }
    }
}

private extension HistoryCalendarView {
    var monthNavigation: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 2) {
                Button {
                    calendarMonth = calendar.date(byAdding: .month, value: -1, to: calendarMonth) ?? calendarMonth
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)

                Button {
                    showMonthPicker = true
                } label: {
                    Text(monthTitle)
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .frame(minWidth: 140, minHeight: 36, alignment: .center)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)

                Button {
                    calendarMonth = calendar.date(byAdding: .month, value: 1, to: calendarMonth) ?? calendarMonth
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.subheadline.weight(.semibold))
                        .frame(width: 32, height: 36)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    var calendarCard: some View {
        VStack(spacing: 0) {
            weekdayHeader
            Divider()
            calendarGrid
        }
        .background(Color(uiColor: .systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(theme.current.primaryLight.opacity(0.9), lineWidth: 1)
        )
        .padding(.horizontal, 16)
        .gesture(
            DragGesture(minimumDistance: 40)
                .onEnded { value in
                    if value.translation.width < -40 {
                        calendarMonth = calendar.date(byAdding: .month, value: 1, to: calendarMonth) ?? calendarMonth
                    } else if value.translation.width > 40 {
                        calendarMonth = calendar.date(byAdding: .month, value: -1, to: calendarMonth) ?? calendarMonth
                    }
                }
        )
    }

    var weekdayHeader: some View {
        HStack(spacing: 0) {
            ForEach(Array(weekdays.enumerated()), id: \.offset) { index, weekday in
                Text(weekday)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .font(.caption)
                    .foregroundStyle(weekdayColor(for: index))
            }
        }
        .background(theme.current.primaryLight.opacity(0.45))
    }

    var calendarGrid: some View {
        VStack(spacing: 0) {
            ForEach(Array(weekRows.enumerated()), id: \.offset) { rowIndex, week in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { index in
                        let date = week[index]
                        DayCellView(
                            date: date,
                            selectedDate: selectedDate,
                            hasPayment: date.map { !payments(for: $0).isEmpty } ?? false,
                            theme: theme,
                            textColor: date.map {
                                let weekday = calendar.component(.weekday, from: $0)
                                let mondayFirstIndex = (weekday - calendar.firstWeekday + 7) % 7
                                return weekdayColor(for: mondayFirstIndex)
                            } ?? .secondary,
                            isToday: date.map(calendar.isDateInToday) ?? false,
                            onTap: {
                                if let date {
                                    selectedDate = date
                                }
                            }
                        )
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .overlay(alignment: .trailing) {
                            if index < 6 {
                                Rectangle()
                                    .fill(theme.current.primaryLight.opacity(0.7))
                                    .frame(width: 0.5)
                            }
                        }
                    }
                }
                if rowIndex < weekRows.count - 1 {
                    Divider()
                }
            }
        }
    }

    var selectedDaySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let selectedDate {
                Text(selectedDateString(for: selectedDate))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 16)

                if payments(for: selectedDate).isEmpty {
                    Text("この日の支払いはありません")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                } else {
                    VStack(spacing: 0) {
                        ForEach(payments(for: selectedDate)) { item in
                            NavigationLink {
                                destination(item)
                            } label: {
                                HStack {
                                    ServiceIconView(service: item.service, size: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(item.service.name)
                                            .font(.subheadline)
                                            .fontWeight(.medium)
                                        Text(item.payment.type.replacingOccurrences(of: "、", with: "\n"))
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Text("¥\(item.payment.amount.formatted())")
                                        .font(.subheadline)
                                        .fontWeight(.semibold)
                                        .foregroundStyle(theme.current.primary)
                                }
                                .padding(.vertical, 4)
                                .padding(.horizontal, 16)
                            }
                            .buttonStyle(.plain)

                            if item.id != payments(for: selectedDate).last?.id {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white)
                    )
                    .padding(.horizontal, 16)
                }
            }
        }
        .padding(.top, 8)
    }

    var calendarDays: [Date?] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: calendarMonth) else {
            return []
        }

        let monthStart = monthInterval.start
        let numberOfDays = calendar.range(of: .day, in: .month, for: monthStart)?.count ?? 0
        let weekday = calendar.component(.weekday, from: monthStart)
        let leadingEmptyDays = (weekday - calendar.firstWeekday + 7) % 7

        var days: [Date?] = Array(repeating: nil, count: leadingEmptyDays)

        for offset in 0..<numberOfDays {
            days.append(calendar.date(byAdding: .day, value: offset, to: monthStart))
        }

        while days.count % 7 != 0 {
            days.append(nil)
        }

        return days
    }

    var weekRows: [[Date?]] {
        stride(from: 0, to: calendarDays.count, by: 7).map {
            Array(calendarDays[$0..<min($0 + 7, calendarDays.count)])
        }
    }

    func payments(for date: Date) -> [HistoryPaymentWithService] {
        payments.filter { calendar.isDate($0.payment.date, inSameDayAs: date) }
    }

    func selectedDateString(for date: Date) -> String {
        ViewDataCommon.monthDayString(from: date)
    }

    var monthTitle: String {
        ViewDataCommon.yearMonthString(from: calendarMonth)
    }

    func weekdayColor(for index: Int) -> Color {
        switch index {
        case 5:
            return .blue
        case 6:
            return .red
        default:
            return .secondary
        }
    }
}

private struct DayCellView: View {
    let date: Date?
    let selectedDate: Date?
    let hasPayment: Bool
    let theme: ThemeManager
    let textColor: Color
    let isToday: Bool
    let onTap: () -> Void

    var body: some View {
        Group {
            if let date {
                Button(action: onTap) {
                    ZStack {
                        if isSelected(date) {
                            Circle()
                                .fill(theme.current.primary)
                                .frame(width: 36, height: 36)
                        }

                        if isToday {
                            Circle()
                                .stroke(theme.current.primary, lineWidth: 1.5)
                                .frame(width: 36, height: 36)
                        }

                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 15))
                            .foregroundStyle(isSelected(date) ? .white : textColor)

                        if hasPayment {
                            Circle()
                                .fill(theme.current.primary)
                                .frame(width: 5, height: 5)
                                .offset(y: 14)
                        }
                    }
                }
                .buttonStyle(.plain)
            } else {
                Color.clear
            }
        }
    }

    private func isSelected(_ date: Date) -> Bool {
        selectedDate.map { Calendar.current.isDate($0, inSameDayAs: date) } ?? false
    }
}

private struct MonthPickerView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Binding var selectedMonth: Date
    @Binding var isPresented: Bool

    @State private var selectedYear: Int
    @State private var selectedMonthNum: Int

    private let years: [Int]
    private let months: [Int] = Array(1...12)

    init(selectedMonth: Binding<Date>, isPresented: Binding<Bool>) {
        self._selectedMonth = selectedMonth
        self._isPresented = isPresented

        let calendar = Calendar.current
        let current = calendar.dateComponents([.year, .month], from: selectedMonth.wrappedValue)
        self._selectedYear = State(initialValue: current.year ?? 2026)
        self._selectedMonthNum = State(initialValue: current.month ?? 1)

        let nowYear = calendar.component(.year, from: Date())
        self.years = Array((nowYear - AppLimits.yearPickerPastRange)...nowYear).reversed()
    }

    var body: some View {
        NavigationStack {
            HStack(spacing: 0) {
                Picker("年", selection: $selectedYear) {
                    ForEach(years, id: \.self) { year in
                        Text("\(String(year))年").tag(year)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .tint(theme.current.primary)

                Picker("月", selection: $selectedMonthNum) {
                    ForEach(months, id: \.self) { month in
                        Text("\(month)月").tag(month)
                    }
                }
                .pickerStyle(.wheel)
                .frame(maxWidth: .infinity)
                .tint(theme.current.primary)
            }
            .padding(.horizontal, 16)
            .navigationTitle("年月を選択")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("閉じる") {
                        isPresented = false
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        var components = DateComponents()
                        components.year = selectedYear
                        components.month = selectedMonthNum
                        components.day = 1

                        if let date = Calendar.current.date(from: components) {
                            selectedMonth = date
                        }
                        isPresented = false
                    }
                }
            }
        }
        .presentationDetents([.height(280)])
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

    return HistoryView()
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
