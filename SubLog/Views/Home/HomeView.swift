import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Query private var services: [Service]

    @State private var showActiveSubscriptions = false

    private let calendar = Calendar.current
    private let cardCornerRadius: CGFloat = 18

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    summaryCard
                    monthlyExpenseCard
                    activeSubscriptionsCard
                }
                .padding(.horizontal, 18)
                .padding(.top, 22)
                .padding(.bottom, 28)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.large)
            .tint(theme.current.primary)
            .sheet(isPresented: $showActiveSubscriptions) {
                ActiveSubscriptionsView()
            }
        }
    }
}

private extension HomeView {
    struct ActiveSubscriptionItem: Identifiable {
        let service: Service
        let subscription: Subscription
        let nextRenewalDate: Date
        let daysUntilRenewal: Int

        var id: PersistentIdentifier { subscription.persistentModelID }
    }

    struct MonthlyExpense: Identifiable {
        let monthStart: Date
        let total: Int
        let isCurrentMonth: Bool

        var id: Date { monthStart }
    }

    var allPayments: [Payment] {
        services.flatMap(\.payments)
    }

    var currentMonthInterval: DateInterval {
        calendar.dateInterval(of: .month, for: .now) ?? DateInterval(start: .now, duration: 1)
    }

    var previousMonthInterval: DateInterval {
        let previousDate = calendar.date(byAdding: .month, value: -1, to: .now) ?? .now
        return calendar.dateInterval(of: .month, for: previousDate) ?? DateInterval(start: previousDate, duration: 1)
    }

    var monthlyTotal: Int {
        allPayments
            .filter { currentMonthInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var previousMonthTotal: Int {
        allPayments
            .filter { previousMonthInterval.contains($0.date) }
            .reduce(0) { $0 + $1.amount }
    }

    var monthComparisonText: String {
        let difference = monthlyTotal - previousMonthTotal

        if previousMonthTotal == 0 {
            if monthlyTotal == 0 {
                return "前月比 ±0円"
            }
            return "前月比 +\(difference.formatted(.number.grouping(.automatic)))円"
        }

        let sign = difference >= 0 ? "+" : "-"
        return "前月比 \(sign)\(abs(difference).formatted(.number.grouping(.automatic)))円"
    }

    var recentMonthlyExpenses: [MonthlyExpense] {
        let currentMonthStart = currentMonthInterval.start

        return (-5...0).compactMap { offset in
            guard let monthStart = calendar.date(byAdding: .month, value: offset, to: currentMonthStart),
                  let monthInterval = calendar.dateInterval(of: .month, for: monthStart) else {
                return nil
            }

            let total = allPayments
                .filter { monthInterval.contains($0.date) }
                .reduce(0) { $0 + $1.amount }

            return MonthlyExpense(
                monthStart: monthStart,
                total: total,
                isCurrentMonth: calendar.isDate(monthStart, equalTo: currentMonthStart, toGranularity: .month)
            )
        }
    }

    var maxMonthlyExpense: Double {
        max(Double(recentMonthlyExpenses.map(\.total).max() ?? 0), 1)
    }

    var activeSubscriptions: [ActiveSubscriptionItem] {
        services
            .filter { !$0.isArchived }
            .flatMap { service in
                service.subscriptions.compactMap { subscription in
                    guard subscription.isActive else { return nil }
                    let nextDate = nextRenewalDate(for: subscription)
                    return ActiveSubscriptionItem(
                        service: service,
                        subscription: subscription,
                        nextRenewalDate: nextDate,
                        daysUntilRenewal: daysUntilRenewal(for: nextDate)
                    )
                }
            }
            .sorted { lhs, rhs in
                if lhs.nextRenewalDate == rhs.nextRenewalDate {
                    return lhs.service.name < rhs.service.name
                }
                return lhs.nextRenewalDate < rhs.nextRenewalDate
            }
            .prefix(5)
            .map { $0 }
    }

    var summaryCard: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            theme.current.primaryLight,
                            theme.current.primary.opacity(0.22),
                            theme.current.primary.opacity(0.42)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            summaryDecoration

            VStack(alignment: .leading, spacing: 8) {
                Text("今月の支払額合計")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(theme.current.primaryDeep.opacity(0.55))

                Text(monthlyTotal, format: .currency(code: "JPY"))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.current.primaryDeep)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(monthComparisonText)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(theme.current.primaryDeep.opacity(0.78))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 22)
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity)
        .shadow(color: Color.black.opacity(0.05), radius: 14, x: 0, y: 8)
    }

    var summaryDecoration: some View {
        ZStack {
            Circle()
                .fill(Color.white.opacity(0.28))
                .frame(width: 84, height: 84)
                .offset(x: 10, y: 24)

            Circle()
                .fill(Color.white.opacity(0.38))
                .frame(width: 18, height: 18)
                .offset(x: 0, y: 8)

            Circle()
                .fill(Color.white.opacity(0.65))
                .frame(width: 10, height: 10)
                .offset(x: 20, y: -2)

            Circle()
                .fill(Color.white.opacity(0.42))
                .frame(width: 8, height: 8)
                .offset(x: -18, y: 18)

            WaveDecoration()
                .fill(Color.white.opacity(0.22))
                .frame(width: 196, height: 88)
                .offset(x: -22, y: 48)
        }
        .frame(width: 188, height: 126)
        .padding(.top, 8)
        .padding(.trailing, 4)
    }

    var monthlyExpenseCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("月別支出")
                .font(.title3.weight(.semibold))
                .foregroundStyle(theme.current.primaryDeep)

            VStack(spacing: 2) {
                chartGrid

                HStack(alignment: .bottom, spacing: 12) {
                    ForEach(recentMonthlyExpenses) { item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(item.isCurrentMonth ? theme.current.primaryDark : theme.current.primary.opacity(0.55))
                                .frame(height: barHeight(for: item))

                            Text(monthLabel(for: item.monthStart))
                                .font(.caption.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, alignment: .bottom)
                    }
                }
                .frame(height: 72, alignment: .bottom)
            }
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 10)
        .cardSurface(cornerRadius: cardCornerRadius)
    }

    var chartGrid: some View {
        VStack(spacing: 0) {
            ForEach(0..<4, id: \.self) { index in
                Rectangle()
                    .fill(Color.black.opacity(index == 3 ? 0.08 : 0.05))
                    .frame(height: 1)

                if index < 3 {
                    Spacer()
                }
            }
        }
        .frame(height: 44)
        .overlay(alignment: .bottom) {
            Rectangle()
                .fill(Color.black.opacity(0.06))
                .frame(height: 1)
        }
    }

    var activeSubscriptionsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .center) {
                Text("利用中のサブスク")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(theme.current.primaryDeep)

                Spacer()

                Button("すべて見る >") {
                    showActiveSubscriptions = true
                }
                .font(.subheadline.weight(.medium))
                .foregroundStyle(theme.current.primary)
            }

            if activeSubscriptions.isEmpty {
                Text("アクティブなサブスクはありません。")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 8)
            } else {
                ForEach(activeSubscriptions) { item in
                    NavigationLink {
                        SubscriptionDetailView(subscription: item.subscription, service: item.service)
                    } label: {
                        HStack(spacing: 12) {
                            ServiceIconView(service: item.service, size: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.service.name)
                                    .font(.headline)
                                    .foregroundStyle(Color.black.opacity(0.84))

                                Text("次回更新 \(renewalDateString(item.nextRenewalDate))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            subscriptionBadge(for: item.daysUntilRenewal)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if item.id != activeSubscriptions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .cardSurface(cornerRadius: cardCornerRadius)
    }

    func barHeight(for item: MonthlyExpense) -> CGFloat {
        let ratio = Double(item.total) / maxMonthlyExpense
        return max(CGFloat(ratio) * 44, item.total > 0 ? 8 : 3)
    }

    func monthLabel(for date: Date) -> String {
        "\(calendar.component(.month, from: date))月"
    }

    func renewalDateString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: date)
    }

    func subscriptionBadge(for daysUntilRenewal: Int) -> some View {
        Text(badgeTitle(for: daysUntilRenewal))
            .font(.caption.weight(.bold))
            .foregroundStyle(badgeForeground(for: daysUntilRenewal))
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(badgeBackground(for: daysUntilRenewal))
            .clipShape(Capsule())
    }

    func badgeTitle(for daysUntilRenewal: Int) -> String {
        if daysUntilRenewal <= 0 {
            return "今日"
        }
        return "あと\(daysUntilRenewal)日"
    }

    func badgeBackground(for daysUntilRenewal: Int) -> Color {
        if daysUntilRenewal <= 3 {
            return Color(red: 1.0, green: 0.91, blue: 0.91)
        } else if daysUntilRenewal <= 10 {
            return Color(red: 1.0, green: 0.94, blue: 0.86)
        } else {
            return Color(red: 0.95, green: 0.95, blue: 0.97)
        }
    }

    func badgeForeground(for daysUntilRenewal: Int) -> Color {
        if daysUntilRenewal <= 3 {
            return Color(red: 0.82, green: 0.28, blue: 0.28)
        } else if daysUntilRenewal <= 10 {
            return Color(red: 0.82, green: 0.49, blue: 0.12)
        } else {
            return Color(red: 0.43, green: 0.45, blue: 0.52)
        }
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
}

private struct WaveDecoration: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: -rect.width * 0.08, y: rect.height * 0.78))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.26, y: rect.height * 0.48),
            control1: CGPoint(x: rect.width * 0.02, y: rect.height * 0.28),
            control2: CGPoint(x: rect.width * 0.14, y: rect.height * 0.98)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.56, y: rect.height * 0.66),
            control1: CGPoint(x: rect.width * 0.36, y: rect.height * 0.16),
            control2: CGPoint(x: rect.width * 0.46, y: rect.height * 0.98)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 0.9, y: rect.height * 0.38),
            control1: CGPoint(x: rect.width * 0.66, y: rect.height * 0.22),
            control2: CGPoint(x: rect.width * 0.78, y: rect.height * 0.90)
        )
        path.addCurve(
            to: CGPoint(x: rect.width * 1.06, y: rect.height * 0.54),
            control1: CGPoint(x: rect.width * 0.96, y: rect.height * 0.04),
            control2: CGPoint(x: rect.width * 1.02, y: rect.height * 0.76)
        )
        path.addLine(to: CGPoint(x: rect.width * 1.06, y: rect.height))
        path.addLine(to: CGPoint(x: -rect.width * 0.08, y: rect.height))
        path.closeSubpath()

        return path
    }
}

private extension View {
    func cardSurface(cornerRadius: CGFloat) -> some View {
        self
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(.white)
                    .shadow(color: .black.opacity(0.06), radius: 16, x: 0, y: 8)
            )
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

    return HomeView()
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .modelContainer(container)
}
