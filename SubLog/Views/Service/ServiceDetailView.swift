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
    var totalAmount: Int {
        service.payments.reduce(0) { $0 + $1.amount }
    }

    var focusedPeriodAmount: Int {
        switch summaryScope {
        case .currentMonth:
            return service.payments
                .filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
        case let .analyticsMonth(date):
            return service.payments
                .filter { calendar.isDate($0.date, equalTo: date, toGranularity: .month) }
                .reduce(0) { $0 + $1.amount }
        case let .analyticsYear(year):
            return service.payments
                .filter { calendar.component(.year, from: $0.date) == year }
                .reduce(0) { $0 + $1.amount }
        }
    }

    var focusedPeriodTitle: String {
        switch summaryScope {
        case .currentMonth, .analyticsMonth:
            return "今月の支払額"
        case .analyticsYear:
            return "今年の支払額"
        }
    }

    var paymentCount: Int {
        service.payments.count
    }

    var sortedPayments: [Payment] {
        service.payments.sorted { lhs, rhs in
            if lhs.date == rhs.date {
                return lhs.type < rhs.type
            }
            return lhs.date > rhs.date
        }
    }

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
            statCard(title: "累計金額", value: totalAmount, isAmount: true)
            statCard(title: focusedPeriodTitle, value: focusedPeriodAmount, isAmount: true)
            statCard(title: "支払回数", value: paymentCount, isAmount: false)
        }
    }

    var paymentHistoryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("支払い履歴")
                .font(.title3.weight(.semibold))

            if sortedPayments.isEmpty {
                Text("課金履歴はまだありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(sortedPayments, id: \.persistentModelID) { payment in
                    HStack(spacing: 12) {
                        Text(payment.date.formatted(historyDateFormat))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(width: 90, alignment: .leading)

                        Image(systemName: "creditcard")
                            .foregroundStyle(theme.current.primary)

                        Text(payment.type.replacingOccurrences(of: "、", with: "\n"))
                            .font(.subheadline)
                            .multilineTextAlignment(.leading)

                        Spacer()

                        Text(payment.amount, format: .currency(code: "JPY"))
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(theme.current.primary)
                    }

                    if payment.persistentModelID != sortedPayments.last?.persistentModelID {
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

    var historyDateFormat: Date.FormatStyle {
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

    return ServiceDetailView(service: services.first!)
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
