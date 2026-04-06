import SwiftUI
import SwiftData

struct PaymentDetailView: View {
    @EnvironmentObject private var theme: ThemeManager
    let payment: Payment
    @State private var showEditSheet = false

    var body: some View {
        NavigationStack {
            Form {
                Section("サービス情報") {
                    LabeledContent("サービス名", value: payment.service.name)
                    LabeledContent("カテゴリ", value: payment.service.category.displayName)
                }

                Section("支払い情報") {
                    LabeledContent("金額") {
                        Text(payment.amount, format: .currency(code: "JPY"))
                    }
                    LabeledContent("支払いタイプ", value: payment.type.replacingOccurrences(of: "、", with: "\n"))
                    LabeledContent("日付", value: payment.date.formatted(detailDateFormat))
                }

                if let memo = payment.memo {
                    Section("メモ") {
                        Text(memo)
                    }
                }

                if let screenshotData = payment.screenshotData,
                   let uiImage = UIImage(data: screenshotData) {
                    Section("スクリーンショット") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        // TODO: EntitlementManager 実装後にプレミアム制限を追加する
                    }
                }
            }
            .navigationTitle(payment.service.name)
            .tint(theme.current.primary)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showEditSheet = true
                    } label: {
                        Image(systemName: "pencil")
                    }
                }
            }
            .sheet(isPresented: $showEditSheet) {
                EditPaymentView(payment: payment)
            }
        }
    }
}

private extension PaymentDetailView {
    var detailDateFormat: Date.FormatStyle {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
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

    return PaymentDetailView(payment: services.flatMap(\.payments).first!)
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
