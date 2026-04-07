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
    @State private var saveErrorMessage: String?

    private var viewData: EditSubscriptionViewData {
        EditSubscriptionViewDataBuilder.build(
            label: label,
            billingType: billingType,
            renewalValueText: renewalValueText,
            renewalUnit: renewalUnit,
            priceText: priceText,
            startDate: startDate,
            memo: memo
        )
    }

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
                    .disabled(!viewData.canSave)
                }
            }
            .onChange(of: billingType) { _, newValue in
                let defaultInterval = EditSubscriptionViewDataBuilder.defaultInterval(for: newValue)
                renewalValueText = String(defaultInterval.value)
                renewalUnit = defaultInterval.unit
            }
            .alert("保存できませんでした", isPresented: saveErrorPresented) {
                Button("OK", role: .cancel) {
                    saveErrorMessage = nil
                }
            } message: {
                Text(saveErrorMessage ?? "サブスクの変更を保存できませんでした。もう一度お試しください。")
            }
        }
    }
}

private extension EditSubscriptionView {
    var saveErrorPresented: Binding<Bool> {
        Binding(
            get: { saveErrorMessage != nil },
            set: { if !$0 { saveErrorMessage = nil } }
        )
    }

    func save() {
        guard viewData.canSave else { return }

        subscription.label = viewData.normalizedLabel
        subscription.billingType = billingType
        subscription.renewalInterval = viewData.renewalInterval
        subscription.price = viewData.priceValue
        subscription.startDate = viewData.startDate
        subscription.memo = viewData.normalizedMemo

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveErrorMessage = "サブスクの変更を保存できませんでした。もう一度お試しください。"
        }
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
