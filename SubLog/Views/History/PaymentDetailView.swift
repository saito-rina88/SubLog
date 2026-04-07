import SwiftUI
import SwiftData
import UIKit

struct PaymentDetailView: View {
    @EnvironmentObject private var theme: ThemeManager
    let payment: Payment
    @State private var showEditSheet = false

    private var viewData: PaymentDetailViewData {
        PaymentDetailViewDataBuilder.build(payment: payment)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("サービス情報") {
                    LabeledContent("サービス名", value: viewData.serviceName)
                    LabeledContent("カテゴリ", value: viewData.categoryName)
                }

                Section("支払い情報") {
                    LabeledContent("金額", value: viewData.amountText)
                    LabeledContent("支払いタイプ", value: viewData.paymentTypeText)
                    LabeledContent("日付", value: viewData.dateText)
                }

                if let memo = viewData.memoText {
                    Section("メモ") {
                        Text(memo)
                    }
                }

                if let uiImage = viewData.screenshotImage {
                    Section("スクリーンショット") {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        // TODO: EntitlementManager 実装後にプレミアム制限を追加する
                    }
                }
            }
            .navigationTitle(viewData.serviceName)
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
