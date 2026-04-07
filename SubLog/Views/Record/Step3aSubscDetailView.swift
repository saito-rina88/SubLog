import SwiftUI
import SwiftData

struct Step3aSubscDetailView: View {
    let serviceID: PersistentIdentifier
    @Binding var path: NavigationPath

    @Query private var allServices: [Service]
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var theme: ThemeManager
    @EnvironmentObject private var notificationManager: NotificationManager

    @State private var amount: String = ""
    @State private var date: Date = Date()
    @State private var memo: String = ""
    @State private var reminderEnabled: Bool = false
    @State private var reminderTime: Date = Calendar.current.date(
        bySettingHour: 9, minute: 0, second: 0, of: Date()
    ) ?? Date()
    @State private var reminderDaysBefore: Int = 3
    @State private var showRenewalIntervalEditor = false
    @State private var renewalValueText = "1"
    @State private var renewalUnit: RenewalIntervalUnit = .month
    @State private var isEditingRenewalValue = false
    @FocusState private var isRenewalValueFocused: Bool

    private var viewData: Step3aSubscDetailViewData {
        Step3aSubscDetailViewDataBuilder.build(
            allServices: allServices,
            serviceID: serviceID,
            amountText: amount,
            renewalValueText: renewalValueText,
            renewalUnit: renewalUnit,
            reminderDaysBefore: reminderDaysBefore
        )
    }

    var body: some View {
        Form {
            Section {
                Text("支払い情報を入力")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 12)
                    .padding(.bottom, -10)
                    .listRowBackground(Color.clear)
            }

            Section("金額") {
                HStack(spacing: 8) {
                    Text("¥")
                        .foregroundStyle(.secondary)
                    TextField("0", text: $amount)
                        .keyboardType(.numberPad)
                }
            }

            Section("更新間隔") {
                Button {
                    loadRenewalInterval()
                    showRenewalIntervalEditor = true
                } label: {
                    HStack {
                        Text(viewData.renewalDisplayText)
                            .foregroundStyle(.primary)
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .buttonStyle(.plain)
            }

            Section("支払日") {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
                    .datePickerStyle(.compact)
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .environment(\.calendar, mondayFirstCalendar)
                    .tint(theme.current.primary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Section("メモ") {
                ZStack(alignment: .topLeading) {
                    if memo.isEmpty {
                        Text("メモ")
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                    }

                    TextEditor(text: $memo)
                        .frame(minHeight: 60)
                        .scrollContentBackground(.hidden)
                }
            }

            Section {
                Toggle(isOn: $reminderEnabled) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .foregroundStyle(theme.current.primary)
                        Text("リマインダー")
                    }
                }
                .tint(theme.current.primary)
                .listRowSeparatorTint(Color(.systemGray4).opacity(0.9))

                if reminderEnabled {
                    DatePicker(
                        "通知時刻",
                        selection: $reminderTime,
                        displayedComponents: .hourAndMinute
                    )
                    .environment(\.locale, Locale(identifier: "ja_JP"))
                    .listRowSeparatorTint(Color(.systemGray4).opacity(0.9))

                    Stepper(value: $reminderDaysBefore, in: 1...7) {
                        HStack {
                            Text("事前通知")
                            Spacer()
                            Text("\(reminderDaysBefore)日前")
                                .foregroundStyle(theme.current.primary)
                                .fontWeight(.medium)
                        }
                    }
                    .listRowSeparatorTint(Color(.systemGray4).opacity(0.9))

                    HStack {
                        Image(systemName: "info.circle")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                        Text(viewData.reminderSummaryText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .listRowSeparatorTint(Color(.systemGray4).opacity(0.9))
                }
            }

            Section {
                Button("記録する") {
                    save()
                }
                .frame(maxWidth: .infinity)
                .foregroundStyle(.white)
                .listRowBackground(theme.current.primary)
                .disabled(!viewData.canSave)
            }
        }
        .padding(.top, -60)
        .scrollContentBackground(.hidden)
        .background(theme.current.primaryXLight)
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            if let price = activeSubscription?.price {
                amount = String(price)
            }
            loadRenewalInterval()
        }
        .sheet(isPresented: $showRenewalIntervalEditor) {
            renewalIntervalSheet
        }
        .onChange(of: isRenewalValueFocused) { _, isFocused in
            if !isFocused {
                commitRenewalValueEditing()
            }
        }
        .safeAreaInset(edge: .bottom) {
            Color.clear
                .frame(height: 56)
        }
    }
}

private extension Step3aSubscDetailView {
    var service: Service? {
        viewData.service
    }

    var activeSubscription: Subscription? {
        viewData.activeSubscription
    }

    var amountValue: Int {
        viewData.amountValue
    }

    var mondayFirstCalendar: Calendar {
        Step3aSubscDetailViewDataBuilder.mondayFirstCalendar
    }

    var renewalValue: Int {
        get { max(Int(renewalValueText) ?? 1, 1) }
        nonmutating set { renewalValueText = String(max(newValue, 1)) }
    }

    var normalizedRenewalValue: Int {
        Step3aSubscDetailViewDataBuilder.normalizedRenewalValue(from: renewalValueText)
    }

    var renewalIntervalSheet: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 10)
                .padding(.bottom, 14)

            ZStack {
                Text("更新間隔")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Button("キャンセル") {
                        showRenewalIntervalEditor = false
                    }
                    .foregroundStyle(.secondary)

                    Spacer()

                    Button("保存") {
                        saveRenewalInterval()
                    }
                    .fontWeight(.bold)
                    .foregroundStyle(theme.current.primary)
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)

            HStack(spacing: 12) {
                HStack {
                    Button {
                        commitRenewalValueEditing()
                        if renewalValue > 1 { renewalValue -= 1 }
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
                                Text(String(renewalValue))
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
                        renewalValue += 1
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
            .padding(.horizontal, 20)

            Spacer()
        }
        .presentationDetents([.height(220)])
        .presentationBackground(Color(.systemBackground))
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("完了") {
                    commitRenewalValueEditing()
                }
            }
        }
    }

    func loadRenewalInterval() {
        guard let activeSubscription else {
            renewalValueText = "1"
            renewalUnit = .month
            return
        }
        renewalValueText = String(activeSubscription.renewalInterval.value)
        renewalUnit = activeSubscription.renewalInterval.unit
    }

    func saveRenewalInterval() {
        guard let service else { return }
        commitRenewalValueEditing()
        let interval = RenewalInterval(value: normalizedRenewalValue, unit: renewalUnit)
        let subscription = ensureActiveSubscription(for: service, renewalInterval: interval)
        subscription.renewalInterval = interval
        subscription.billingType = billingType(for: interval)
        if subscription.price <= 0, amountValue > 0 {
            subscription.price = amountValue
        }
        try? modelContext.save()
        showRenewalIntervalEditor = false
    }

    func commitRenewalValueEditing() {
        renewalValueText = String(normalizedRenewalValue)
        isEditingRenewalValue = false
        isRenewalValueFocused = false
    }

    func ensureActiveSubscription(for service: Service, renewalInterval: RenewalInterval) -> Subscription {
        if let activeSubscription {
            return activeSubscription
        }

        let subscription = Subscription(
            label: service.name,
            billingType: billingType(for: renewalInterval),
            price: amountValue,
            startDate: date,
            service: service,
            renewalInterval: renewalInterval
        )
        modelContext.insert(subscription)
        service.subscriptions.append(subscription)
        return subscription
    }

    func billingType(for renewalInterval: RenewalInterval) -> BillingType {
        Step3aSubscDetailViewDataBuilder.billingType(for: renewalInterval)
    }

    func save() {
        guard let service, let amount = Int(amount), amount > 0 else { return }
        let interval = RenewalInterval(value: normalizedRenewalValue, unit: renewalUnit)
        let subscription = ensureActiveSubscription(for: service, renewalInterval: interval)

        let payment = Payment(
            date: date,
            amount: amount,
            type: "サブスク更新",
            service: service,
            subscription: subscription,
            memo: memo.trimmedNilIfEmpty
        )
        modelContext.insert(payment)
        service.payments.append(payment)
        subscription.payments.append(payment)

        do {
            try modelContext.save()

            if reminderEnabled {
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
                        notificationManager.removeReminderSettings(for: subscription)
                        return
                    }

                    await notificationManager.scheduleNotification(
                        for: subscription,
                        daysBefore: 0,
                        hour: hour,
                        minute: minute
                    )

                    if daysBefore > 0 {
                        await notificationManager.scheduleNotification(
                            for: subscription,
                            daysBefore: daysBefore,
                            hour: hour,
                            minute: minute
                        )
                    }
                }
            } else {
                notificationManager.removeReminderSettings(for: subscription)
                Task {
                    await notificationManager.cancelReminder(for: subscription)
                }
            }

            path = NavigationPath()
            dismiss()
        } catch {
            return
        }
    }
}

private extension String {
    var trimmedNilIfEmpty: String? {
        let trimmed = trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
