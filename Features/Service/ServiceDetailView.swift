import SwiftUI
import SwiftData

struct ServiceDetailView: View {
    enum SummaryScope {
        case currentMonth
        case analyticsMonth(Date)
        case analyticsYear(Int)
    }

    @EnvironmentObject private var theme: ThemeManager
    let service: Service
    let summaryScope: SummaryScope

    private let calendar = Calendar.current

    private var viewData: ServiceDetailViewData {
        ServiceDetailViewDataBuilder.build(
            service: service,
            summaryScope: summaryScope,
            calendar: calendar
        )
    }

    init(service: Service, summaryScope: SummaryScope = .currentMonth) {
        self.service = service
        self.summaryScope = summaryScope
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    headerSection
                    statCardsSection
                    paymentHistoryCard
                }
                .padding(20)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
        }
    }
}

private extension ServiceDetailView {
    var headerSection: some View {
        HStack(spacing: 14) {
            ServiceIconView(service: service, size: 44)
                .background(
                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                        .fill(Color(.systemBackground))
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(service.name)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundStyle(theme.current.primaryDeep)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(theme.current.primaryMid.opacity(0.15))
        .cornerRadius(12)
    }

    var statCardsSection: some View {
        HStack(spacing: 12) {
            statCard(title: "累計金額", value: viewData.totalAmount, isAmount: true)
            statCard(title: viewData.focusedPeriodTitle, value: viewData.focusedPeriodAmount, isAmount: true)
            statCard(title: "支払回数", value: viewData.paymentCount, isAmount: false)
        }
    }

    var paymentHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支払い履歴")
                .font(.title3.weight(.semibold))

            if viewData.isPaymentHistoryEmpty {
                Text("課金履歴はまだありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(viewData.paymentRows) { row in
                    HStack(spacing: 12) {
                        Text(row.formattedDate)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 90, alignment: .leading)

                        Image(systemName: "creditcard")
                            .foregroundStyle(theme.current.primary)

                        Text(row.payment.type.replacingOccurrences(of: "、", with: "\n"))
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Text(row.payment.amount, format: .currency(code: "JPY"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.current.primary)
                    }

                    if row.id != viewData.paymentRows.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.08), radius: 14, x: 0, y: 6)
        )
    }

    func statCard(title: String, value: Int, isAmount: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            if isAmount {
                Text(value, format: .currency(code: "JPY"))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
            } else {
                Text("\(value)回")
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(.orange)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
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

    return ServiceDetailView(service: services.first!)
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
