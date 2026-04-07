import SwiftUI
import SwiftData

struct HomeView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Query private var services: [Service]

    @State private var showActiveSubscriptions = false

    private let calendar = Calendar.current
    private let cardCornerRadius: CGFloat = 18

    private var dashboardData: HomeDashboardData {
        HomeDashboardBuilder.make(services: services, calendar: calendar)
    }

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

                Text(dashboardData.monthlyTotal, format: .currency(code: "JPY"))
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(theme.current.primaryDeep)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)

                Text(dashboardData.monthComparisonText)
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
                    ForEach(dashboardData.recentMonthlyExpenses) { item in
                        VStack(spacing: 4) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(item.isCurrentMonth ? theme.current.primaryDark : theme.current.primary.opacity(0.55))
                                .frame(height: barHeight(for: item))

                            Text(item.monthLabel)
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
                ForEach(dashboardData.activeSubscriptions) { item in
                    NavigationLink {
                        SubscriptionDetailView(subscription: item.subscription, service: item.service)
                    } label: {
                        HStack(spacing: 12) {
                            ServiceIconView(service: item.service, size: 44)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.service.name)
                                    .font(.headline)
                                    .foregroundStyle(Color.black.opacity(0.84))

                                Text("次回更新 \(item.nextRenewalDateText)")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()

                            subscriptionBadge(for: item)
                        }
                        .padding(.vertical, 4)
                    }
                    .buttonStyle(.plain)

                    if item.id != dashboardData.activeSubscriptions.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(18)
        .cardSurface(cornerRadius: cardCornerRadius)
    }

    var activeSubscriptions: [HomeActiveSubscriptionItem] {
        dashboardData.activeSubscriptions
    }

    func barHeight(for item: HomeMonthlyExpense) -> CGFloat {
        let ratio = Double(item.total) / dashboardData.maxMonthlyExpense
        return max(CGFloat(ratio) * 44, item.total > 0 ? 8 : 3)
    }

    func subscriptionBadge(for item: HomeActiveSubscriptionItem) -> some View {
        Text(item.badgeTitle)
            .font(.caption.weight(.bold))
            .foregroundStyle(item.badgeForegroundColor)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(item.badgeBackgroundColor)
            .clipShape(Capsule())
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
