import SwiftUI
import SwiftData

struct EditSubscriptionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    var subscription: Subscription

    @State private var label: String
    @State private var billingType: BillingType
    @State private var renewalValueText: String
    @State private var renewalUnit: RenewalIntervalUnit
    @State private var priceText: String
    @State private var startDate: Date
    @State private var memo: String

    init(subscription: Subscription) {
        self.subscription = subscription
        _label = State(initialValue: subscription.label)
        _billingType = State(initialValue: subscription.billingType)
        _renewalValueText = State(initialValue: String(subscription.renewalInterval.value))
        _renewalUnit = State(initialValue: subscription.renewalInterval.unit)
        _priceText = State(initialValue: String(subscription.price))
        _startDate = State(initialValue: subscription.startDate)
        _memo = State(initialValue: subscription.memo ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("テンプレート名") {
                    TextField("サブスク名", text: $label)
                }

                Section("課金タイプ") {
                    Picker("課金タイプ", selection: $billingType) {
                        ForEach(BillingType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("更新間隔") {
                    HStack {
                        TextField("回数", text: $renewalValueText)
                            .keyboardType(.numberPad)
                        Picker("単位", selection: $renewalUnit) {
                            ForEach(RenewalIntervalUnit.allCases, id: \.self) { unit in
                                Text(unit.displayName).tag(unit)
                            }
                        }
                    }
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(billingType == .seasonal ? theme.current.primaryLight : .clear)
                    )
                }

                Section("金額") {
                    TextField("金額", text: $priceText)
                        .keyboardType(.numberPad)
                }

                Section("開始日") {
                    DatePicker("開始日", selection: $startDate, displayedComponents: .date)
                }

                Section("メモ") {
                    TextField("メモ", text: $memo)
                }
            }
            .navigationTitle("サブスクを編集")
            .tint(theme.current.primary)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button("保存") {
                        save()
                    }
                    .disabled(trimmedLabel.isEmpty || priceValue <= 0 || renewalValue <= 0)
                }
            }
            .onChange(of: billingType) { _, newValue in
                renewalValueText = String(newValue.defaultInterval.value)
                renewalUnit = newValue.defaultInterval.unit
            }
        }
    }
}

private extension EditSubscriptionView {
    var trimmedLabel: String {
        label.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var renewalValue: Int {
        Int(renewalValueText) ?? 0
    }

    var priceValue: Int {
        Int(priceText) ?? 0
    }

    func save() {
        guard !trimmedLabel.isEmpty, priceValue > 0, renewalValue > 0 else { return }

        subscription.label = trimmedLabel
        subscription.billingType = billingType
        subscription.renewalInterval = RenewalInterval(value: renewalValue, unit: renewalUnit)
        subscription.price = priceValue
        subscription.startDate = startDate
        subscription.memo = memo.nilIfEmpty

        try? modelContext.save()
        dismiss()
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
    let subscriptionService = services.first { $0.serviceType == .subscription }!

    return EditSubscriptionView(subscription: subscriptionService.subscriptions[0])
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
