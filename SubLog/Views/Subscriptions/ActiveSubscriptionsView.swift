import SwiftUI
import SwiftData

struct ActiveSubscriptionsView: View {
    struct ActiveSubscriptionItem: Identifiable {
        let service: Service
        let subscription: Subscription
        let nextRenewalDate: Date
        let daysUntilRenewal: Int

        var id: PersistentIdentifier { subscription.persistentModelID }
    }

    private enum SortType: String, CaseIterable, Identifiable {
        case nextRenewal = "次回更新順"
        case priceDescending = "月額降順"
        case priceAscending = "月額昇順"
        case name = "名前順"

        var id: Self { self }
    }

    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Query private var services: [Service]

    @State private var selectedSort: SortType = .nextRenewal

    private let showsNavigationStack: Bool
    private let calendar = Calendar.current

    init(showsNavigationStack: Bool = true) {
        self.showsNavigationStack = showsNavigationStack
    }

    @ViewBuilder
    var body: some View {
        if showsNavigationStack {
            NavigationStack {
                content
            }
        } else {
            content
        }
    }
}

private extension ActiveSubscriptionsView {
    var content: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerSection

                    if sortedSubscriptions.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(sortedSubscriptions) { item in
                                NavigationLink {
                                    SubscriptionDetailView(subscription: item.subscription, service: item.service)
                                } label: {
                                    subscriptionCard(for: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.top, 2)
                .padding(.bottom, 24)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(theme.current.primary)
            .toolbar(showsNavigationStack ? .visible : .hidden, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Color.clear
                        .frame(width: 1, height: 1)
                }
            }
    }

    var activeSubscriptions: [ActiveSubscriptionItem] {
        services
            .filter { !$0.isArchived }
            .flatMap { service in
                service.subscriptions
                    .filter { $0.isActive }
                    .map { subscription in
                        let nextDate = nextRenewalDate(for: subscription)
                        return ActiveSubscriptionItem(
                            service: service,
                            subscription: subscription,
                            nextRenewalDate: nextDate,
                            daysUntilRenewal: daysUntilRenewal(for: nextDate)
                        )
                    }
            }
    }

    var sortedSubscriptions: [ActiveSubscriptionItem] {
        switch selectedSort {
        case .nextRenewal:
            return activeSubscriptions.sorted { lhs, rhs in
                if lhs.nextRenewalDate == rhs.nextRenewalDate {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.nextRenewalDate < rhs.nextRenewalDate
            }
        case .priceDescending:
            return activeSubscriptions.sorted { lhs, rhs in
                if lhs.subscription.price == rhs.subscription.price {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.subscription.price > rhs.subscription.price
            }
        case .priceAscending:
            return activeSubscriptions.sorted { lhs, rhs in
                if lhs.subscription.price == rhs.subscription.price {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.subscription.price < rhs.subscription.price
            }
        case .name:
            return activeSubscriptions.sorted { $0.service.name < $1.service.name }
        }
    }

    var monthlyTotal: Int {
        sortedSubscriptions.reduce(0) { $0 + $1.subscription.price }
    }

    var headerSection: some View {
        VStack(spacing: 12) {
            ZStack {
                Text("利用中のサブスク")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, alignment: .center)

                HStack {
                    Spacer()

                    Menu {
                        ForEach(SortType.allCases) { sort in
                            Button {
                                selectedSort = sort
                            } label: {
                                if selectedSort == sort {
                                    Label(sort.rawValue, systemImage: "checkmark")
                                } else {
                                    Text(sort.rawValue)
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(theme.current.primary)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(.white)
                            )
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .padding(.top, 0)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(monthlyTotal, format: .currency(code: "JPY"))
                    .font(.title2.weight(.bold))
                    .foregroundStyle(theme.current.primary)

                Text("/月　\(sortedSubscriptions.count)件契約中")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.top, 0)
    }

    var emptyState: some View {
        VStack(spacing: 10) {
            Image(systemName: "square.grid.2x2")
                .font(.system(size: 34, weight: .regular))
                .foregroundStyle(.secondary)

            Text("表示できるサブスクがありません")
                .font(.headline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, minHeight: 260)
    }

    func subscriptionCard(for item: ActiveSubscriptionItem) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ServiceIconView(service: item.service, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.service.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)

                Text(item.subscription.price, format: .currency(code: "JPY"))
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.current.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("次回更新 \(nextRenewalDateFormatter.string(from: item.nextRenewalDate))")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 8)

            dayBadge(for: item.daysUntilRenewal)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 13)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.white)
                .shadow(color: .black.opacity(0.06), radius: 10, x: 0, y: 4)
        )
    }

    func dayBadge(for days: Int) -> some View {
        Text(daysText(for: days))
            .font(.caption.weight(.bold))
            .foregroundStyle(daysColor(for: days))
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(daysBackground(for: days))
            .clipShape(Capsule())
    }

    func nextRenewalDate(for subscription: Subscription) -> Date {
        let component = subscription.renewalInterval.unit.calendarComponent
        var candidate = subscription.startDate

        while candidate < .now {
            candidate = calendar.date(
                byAdding: component,
                value: subscription.renewalInterval.value,
                to: candidate
            ) ?? candidate
        }

        return candidate
    }

    func daysUntilRenewal(for nextRenewalDate: Date) -> Int {
        calendar.dateComponents([.day], from: .now, to: nextRenewalDate).day ?? 0
    }

    func daysText(for days: Int) -> String {
        if days <= 0 {
            return "今日"
        }
        return "\(days)日"
    }

    func daysColor(for days: Int) -> Color {
        if days <= 3 {
            return Color(red: 0.82, green: 0.28, blue: 0.28)
        }
        if days <= 10 {
            return Color(red: 0.82, green: 0.49, blue: 0.12)
        }
        return Color(red: 0.43, green: 0.45, blue: 0.52)
    }

    func daysBackground(for days: Int) -> Color {
        if days <= 3 {
            return Color(red: 1.0, green: 0.91, blue: 0.91)
        }
        if days <= 10 {
            return Color(red: 1.0, green: 0.94, blue: 0.86)
        }
        return Color(red: 0.95, green: 0.95, blue: 0.97)
    }

    var nextRenewalDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter
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

    return ActiveSubscriptionsView()
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
