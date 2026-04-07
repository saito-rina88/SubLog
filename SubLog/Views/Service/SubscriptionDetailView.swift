import SwiftUI
import SwiftData

struct SubscriptionDetailView: View {
    enum SubscriptionField: String, Identifiable {
        case price
        case billingType
        case renewalInterval
        case startDate
        case memo

        var id: String { rawValue }
    }

    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var notificationManager: NotificationManager
    @EnvironmentObject private var theme: ThemeManager

    let subscription: Subscription
    let service: Service

    @State private var showCancelAlert = false
    @State private var editingField: SubscriptionField?
    @State private var isReminderOn = false
    @State private var reminderTime: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var reminderDaysBefore: Int = 3
    @State private var showNotificationPermissionAlert = false

    private let calendar = Calendar.current

    private var viewData: SubscriptionDetailViewData {
        SubscriptionDetailViewDataBuilder.build(
            subscription: subscription,
            reminderDaysBefore: reminderDaysBefore,
            calendar: calendar
        )
    }

    init(subscription: Subscription, service: Service) {
        self.subscription = subscription
        self.service = service

        let initialState = SubscriptionDetailViewDataBuilder.initialReminderState(
            for: subscription,
            notificationManager: NotificationManager()
        )
        _isReminderOn = State(initialValue: initialState.isEnabled)
        _reminderTime = State(initialValue: initialState.time)
        _reminderDaysBefore = State(initialValue: initialState.daysBefore)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                subscriptionInfoCard
                subscriptionManagementCard
            }
            .padding(20)
        }
        .background(theme.current.primaryXLight.ignoresSafeArea())
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .tint(theme.current.primary)
        .alert("解約済みとしてマークしますか？", isPresented: $showCancelAlert) {
            Button("キャンセル", role: .cancel) {}
            Button("解約済みにする", role: .destructive) {
                subscription.isActive = false
                subscription.canceledDate = .now
                try? modelContext.save()
                Task {
                    await notificationManager.cancelReminder(for: subscription)
                }
            }
        } message: {
            Text("この契約を解約済みとして扱います。")
        }
        .alert("通知を許可できませんでした", isPresented: $showNotificationPermissionAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("設定アプリで通知を許可すると、更新日リマインダーを利用できます。")
        }
        .sheet(item: $editingField) { field in
            SubscriptionInlineEditSheet(subscription: subscription, field: field)
        }
        .onChange(of: reminderTime) { _, _ in
            guard isReminderOn else { return }
            saveReminderConfiguration()
        }
        .onChange(of: reminderDaysBefore) { _, _ in
            guard isReminderOn else { return }
            saveReminderConfiguration()
        }
    }
}

private extension SubscriptionDetailView {
    var headerSection: some View {
        HStack(spacing: 14) {
            ServiceIconView(service: service, size: 44)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(.systemBackground))
                )
            Text(subscription.label)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundStyle(theme.current.primaryDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.current.primaryMid.opacity(0.15))
        .cornerRadius(12)
    }

    var subscriptionInfoCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                infoButtonRow(title: "金額", value: subscription.price.formatted(.currency(code: "JPY")), field: .price)

                renewalIntervalRow

                if let nextText = viewData.nextRenewalDateText, let renewalBadgeText = viewData.renewalBadgeText {
                    HStack {
                        Text("次回更新日")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(nextText)
                            .foregroundStyle(.primary)
                        Text(renewalBadgeText)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(viewData.isRenewalSoon ? theme.current.primaryDark : theme.current.primary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(viewData.isRenewalSoon ? theme.current.primaryLight : theme.current.primaryXLight)
                            .cornerRadius(6)
                    }
                }

                infoButtonRow(
                    title: "メモ",
                    value: subscription.memo ?? "未設定",
                    field: .memo
                )

                infoButtonRow(
                    title: "開始日",
                    value: subscription.startDate.formatted(date: .numeric, time: .omitted),
                    field: .startDate
                )

                if subscription.isActive {
                    Divider()

                    Toggle(isOn: $isReminderOn) {
                        HStack(spacing: 10) {
                            Image(systemName: "bell.fill")
                                .foregroundStyle(theme.current.primary)
                            Text("リマインダー")
                        }
                    }
                        .tint(theme.current.primary)
                        .onChange(of: isReminderOn) { _, newValue in
                            handleReminderChange(newValue)
                        }

                    if isReminderOn {
                        DatePicker(
                            "通知時刻",
                            selection: $reminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .environment(\.locale, Locale(identifier: "ja_JP"))

                        Stepper(value: $reminderDaysBefore, in: 1...7) {
                            HStack {
                                Text("事前通知")
                                Spacer()
                                Text("\(reminderDaysBefore)日前")
                                    .foregroundStyle(theme.current.primary)
                                    .fontWeight(.medium)
                            }
                        }

                        HStack {
                            Image(systemName: "info.circle")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                            Text(viewData.reminderSummaryText)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }

    var subscriptionManagementCard: some View {
        card {
            VStack(alignment: .leading, spacing: 12) {
                Text("サブスク管理")
                    .font(.headline)

                if subscription.isActive {
                    HStack(spacing: 6) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("利用中")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.bottom, 4)

                    Button {
                        showCancelAlert = true
                    } label: {
                        Label("解約済みにする", systemImage: "xmark.circle")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.secondary)
                        Text("解約済み")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let canceledDateText = viewData.canceledDateText {
                            Text("（\(canceledDateText)）")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.vertical, 4)

                    Button {
                        subscription.isActive = true
                        subscription.canceledDate = nil
                        try? modelContext.save()
                    } label: {
                        Label("再開する", systemImage: "arrow.clockwise")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundStyle(theme.current.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(theme.current.primaryXLight)
                            .cornerRadius(10)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    var renewalIntervalRow: some View {
        Button {
            editingField = .renewalInterval
        } label: {
            HStack(spacing: 10) {
                Text("更新間隔")
                    .foregroundStyle(.secondary)

                Spacer()

                Text(subscription.renewalInterval.displayText)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    func infoButtonRow(title: String, value: String, field: SubscriptionField) -> some View {
        Button {
            editingField = field
        } label: {
            HStack(spacing: 10) {
                Text(title)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(value)
                    .fontWeight(.medium)
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.trailing)
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
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

    func refreshReminderState() {
        let reminderState = SubscriptionDetailViewDataBuilder.initialReminderState(
            for: subscription,
            notificationManager: notificationManager
        )
        isReminderOn = reminderState.isEnabled
        reminderTime = reminderState.time
        reminderDaysBefore = reminderState.daysBefore
    }

    func handleReminderChange(_ newValue: Bool) {
        guard subscription.isActive else { return }

        if newValue {
            let settings = notificationManager.reminderSettings(for: subscription)
                ?? .init(hour: 9, minute: 0, daysBefore: reminderDaysBefore)

            reminderTime = Calendar.current.date(
                bySettingHour: settings.hour,
                minute: settings.minute,
                second: 0,
                of: Date()
            ) ?? Date()
            reminderDaysBefore = max(settings.daysBefore, 1)

            notificationManager.saveReminderSettings(
                for: subscription,
                hour: settings.hour,
                minute: settings.minute,
                daysBefore: settings.daysBefore
            )

            Task {
                let granted = await notificationManager.requestAuthorization()
                guard granted else {
                    isReminderOn = false
                    notificationManager.removeReminderSettings(for: subscription)
                    showNotificationPermissionAlert = true
                    return
                }

                await notificationManager.scheduleNotification(
                    for: subscription,
                    daysBefore: 0,
                    hour: settings.hour,
                    minute: settings.minute
                )

                if settings.daysBefore > 0 {
                    await notificationManager.scheduleNotification(
                        for: subscription,
                        daysBefore: settings.daysBefore,
                        hour: settings.hour,
                        minute: settings.minute
                    )
                }

                await MainActor.run {
                    refreshReminderState()
                }
            }
        } else {
            notificationManager.removeReminderSettings(for: subscription)

            Task {
                await notificationManager.cancelReminder(for: subscription)
                await MainActor.run {
                    refreshReminderState()
                }
            }
        }
    }

    func saveReminderConfiguration() {
        let hour = Calendar.current.component(.hour, from: reminderTime)
        let minute = Calendar.current.component(.minute, from: reminderTime)
        let daysBefore = reminderDaysBefore

        notificationManager.saveReminderSettings(
            for: subscription,
            hour: hour,
            minute: minute,
            daysBefore: daysBefore
        )

        Task {
            let granted = await notificationManager.requestAuthorization()
            guard granted else {
                await MainActor.run {
                    isReminderOn = false
                    notificationManager.removeReminderSettings(for: subscription)
                    showNotificationPermissionAlert = true
                }
                return
            }

            await notificationManager.cancelReminder(for: subscription)
            await notificationManager.scheduleNotification(
                for: subscription,
                daysBefore: 0,
                hour: hour,
                minute: minute
            )
            await notificationManager.scheduleNotification(
                for: subscription,
                daysBefore: daysBefore,
                hour: hour,
                minute: minute
            )
        }
    }
}

private struct SubscriptionInlineEditSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    let subscription: Subscription
    let field: SubscriptionDetailView.SubscriptionField

    @State private var priceText: String
    @State private var billingType: BillingType
    @State private var renewalValueText: String
    @State private var renewalUnit: RenewalIntervalUnit
    @State private var startDate: Date
    @State private var memo: String
    @State private var isEditingRenewalValue = false
    @FocusState private var isRenewalValueFocused: Bool

    init(subscription: Subscription, field: SubscriptionDetailView.SubscriptionField) {
        self.subscription = subscription
        self.field = field
        _priceText = State(initialValue: String(subscription.price))
        _billingType = State(initialValue: subscription.billingType)
        _renewalValueText = State(initialValue: String(subscription.renewalInterval.value))
        _renewalUnit = State(initialValue: subscription.renewalInterval.unit)
        _startDate = State(initialValue: subscription.startDate)
        _memo = State(initialValue: subscription.memo ?? "")
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                RoundedRectangle(cornerRadius: 2.5)
                    .fill(Color(.systemGray4))
                    .frame(width: 36, height: 5)
                Spacer()
            }
            .padding(.top, 10)
            .padding(.bottom, 14)

            ZStack {
                Text(fieldTitle)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Button("キャンセル") { dismiss() }
                        .foregroundStyle(.secondary)
                    Spacer()
                    Button("保存") { save() }
                        .fontWeight(.bold)
                        .foregroundStyle(theme.current.primary)
                        .disabled(!canSave)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            inputView
                .padding(.horizontal, 20)

            Spacer()
        }
        .onChange(of: billingType) { _, newValue in
            if field == .billingType {
                renewalValueText = String(newValue.defaultInterval.value)
                renewalUnit = newValue.defaultInterval.unit
            }
        }
        .presentationDetents([.height(sheetHeight)])
        .presentationBackground(Color(.systemBackground))
        .presentationDragIndicator(.hidden)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    commitRenewalValueEditing()
                }
            }
        }
    }
}

private extension SubscriptionInlineEditSheet {
    @ViewBuilder
    var inputView: some View {
        switch field {
        case .price:
            HStack(spacing: 4) {
                Text("¥")
                    .font(.body)
                    .foregroundStyle(.secondary)
                TextField("0", text: $priceText)
                    .font(.body)
                    .keyboardType(.numberPad)
            }
            .padding(14)
            .background(Color(.systemGray6))
            .cornerRadius(10)

        case .billingType:
            VStack {
                Picker("", selection: $billingType) {
                    ForEach(BillingType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.wheel)
                .frame(height: 160)
            }

        case .renewalInterval:
            HStack(spacing: 12) {
                HStack {
                    Button {
                        commitRenewalValueEditing()
                        if intervalValue > 1 { intervalValue -= 1 }
                    } label: {
                        Image(systemName: "minus")
                    }

                    Group {
                        if isEditingRenewalValue {
                            TextField("1", text: $renewalValueText)
                                .keyboardType(.numberPad)
                                .multilineTextAlignment(.center)
                                .font(.title3)
                                .fontWeight(.semibold)
                                .frame(minWidth: 40)
                                .focused($isRenewalValueFocused)
                        } else {
                            Button {
                                isEditingRenewalValue = true
                                isRenewalValueFocused = true
                            } label: {
                                Text(String(intervalValue))
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .frame(minWidth: 40)
                                    .foregroundStyle(.primary)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    Button {
                        commitRenewalValueEditing()
                        intervalValue += 1
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                .padding(12)
                .background(Color(.systemGray6))
                .cornerRadius(10)

                Picker("", selection: $renewalUnit) {
                    ForEach(RenewalIntervalUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(unit)
                    }
                }
                .pickerStyle(.segmented)
            }

        case .startDate:
            DatePicker("", selection: $startDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .environment(\.locale, Locale(identifier: "ja_JP"))
                .environment(\.calendar, mondayFirstCalendar)
                .accentColor(theme.current.primary)
                .frame(maxWidth: .infinity)

        case .memo:
            ZStack(alignment: .topLeading) {
                TextEditor(text: $memo)
                    .font(.body)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)

                if memo.isEmpty {
                    Text("メモを入力（任意）")
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 16)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    var fieldTitle: String {
        switch field {
        case .price:
            return "金額"
        case .billingType:
            return "課金タイプ"
        case .renewalInterval:
            return "更新間隔"
        case .startDate:
            return "開始日"
        case .memo:
            return "メモ"
        }
    }

    var sheetHeight: CGFloat {
        switch field {
        case .price:
            return 180
        case .billingType:
            return 280
        case .renewalInterval:
            return 220
        case .startDate:
            return 440
        case .memo:
            return 300
        }
    }

    var intervalValue: Int {
        get { max(Int(renewalValueText) ?? 1, 1) }
        nonmutating set { renewalValueText = String(max(newValue, 1)) }
    }

    var canSave: Bool {
        switch field {
        case .price:
            return (Int(priceText) ?? 0) > 0
        case .billingType:
            return true
        case .renewalInterval:
            return (Int(renewalValueText) ?? 0) > 0
        case .startDate:
            return true
        case .memo:
            return true
        }
    }

    func save() {
        commitRenewalValueEditing()
        switch field {
        case .price:
            subscription.price = Int(priceText) ?? subscription.price

        case .billingType:
            subscription.billingType = billingType
            subscription.renewalInterval = billingType.defaultInterval

        case .renewalInterval:
            subscription.renewalInterval = RenewalInterval(value: intervalValue, unit: renewalUnit)

        case .startDate:
            subscription.startDate = startDate

        case .memo:
            subscription.memo = memo.nilIfEmpty
        }

        try? modelContext.save()
        dismiss()
    }

    var mondayFirstCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "ja_JP")
        calendar.firstWeekday = 2
        return calendar
    }

    func commitRenewalValueEditing() {
        intervalValue = intervalValue
        isEditingRenewalValue = false
        isRenewalValueFocused = false
    }
}

private extension String {
    var nilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}

#Preview {
    let container = try! ModelContainer(
        for: Service.self,
        configurations: ModelConfiguration(isStoredInMemoryOnly: true)
    )
    let services = SampleDataFactory.makeServices()
    services.forEach {
        container.mainContext.insert($0)
    }
    let service = services.first { $0.serviceType == .subscription }!

    return SubscriptionDetailView(subscription: service.subscriptions[0], service: service)
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .environmentObject(ThemeManager())
        .modelContainer(container)
}
