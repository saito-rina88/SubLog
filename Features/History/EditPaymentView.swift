import SwiftUI
import SwiftData

struct EditPaymentView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var theme: ThemeManager

    var payment: Payment

    @State private var date: Date
    @State private var amountText: String
    @State private var type: String
    @State private var itemName: String
    @State private var memo: String

    private var viewData: EditPaymentViewData {
        EditPaymentViewDataBuilder.build(amountText: amountText)
    }

    init(payment: Payment) {
        self.payment = payment
        _date = State(initialValue: payment.date)
        _amountText = State(initialValue: String(payment.amount))
        _type = State(initialValue: payment.type)
        _itemName = State(initialValue: payment.itemName ?? "")
        _memo = State(initialValue: payment.memo ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("日付") {
                    DatePicker("支払日", selection: $date, displayedComponents: .date)
                }

                Section("金額") {
                    TextField("金額", text: $amountText)
                        .keyboardType(.numberPad)
                }

                Section("購入内容") {
                    TextField("購入内容", text: $type)
                }

                Section("項目名") {
                    TextField("項目名", text: $itemName)
                }

                Section("メモ") {
                    TextField("メモ", text: $memo)
                }
            }
            .navigationTitle("支払いを編集")
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
        }
    }
}

private extension EditPaymentView {
    func save() {
        guard viewData.canSave else { return }

        payment.date = date
        payment.amount = viewData.amountValue
        payment.type = type
        payment.itemName = EditPaymentViewDataBuilder.normalizedOptionalText(itemName)
        payment.memo = EditPaymentViewDataBuilder.normalizedOptionalText(memo)

        try? modelContext.save()
        dismiss()
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

    return EditPaymentView(payment: services.flatMap(\.payments).first!)
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
