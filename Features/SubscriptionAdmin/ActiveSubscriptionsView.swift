import SwiftUI
import SwiftData

struct ActiveSubscriptionsView: View {
    @EnvironmentObject private var theme: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @Query private var services: [Service]

    @State private var selectedSort: ActiveSubscriptionsSortType = .nextRenewal

    private let showsNavigationStack: Bool

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
    var viewData: ActiveSubscriptionsViewData {
        ActiveSubscriptionsViewDataBuilder.build(
            services: services,
            selectedSort: selectedSort
        )
    }

    var content: some View {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 14) {
                    headerSection

                    if viewData.items.isEmpty {
                        emptyState
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(viewData.items) { item in
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
                        ForEach(ActiveSubscriptionsSortType.allCases) { sort in
                            Button {
                                selectedSort = sort
                            } label: {
                                if selectedSort == sort {
                                    Label(sort.title, systemImage: "checkmark")
                                } else {
                                    Text(sort.title)
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
                Text(viewData.monthlyTotalText)
                    .font(.title2.weight(.bold))
                    .foregroundStyle(theme.current.primary)

                Text("/月　\(viewData.items.count)件契約中")
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

    func subscriptionCard(for item: ActiveSubscriptionRowData) -> some View {
        HStack(alignment: .center, spacing: 12) {
            ServiceIconView(service: item.service, size: 46)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.service.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.black)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .minimumScaleFactor(0.75)

                Text(item.priceText)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(theme.current.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)

                Text("次回更新 \(item.nextRenewalDateText)")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }

            Spacer(minLength: 8)

            dayBadge(for: item)
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

    func dayBadge(for item: ActiveSubscriptionRowData) -> some View {
        Text(item.daysText)
            .font(.caption.weight(.bold))
            .foregroundStyle(item.daysColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .background(item.daysBackground)
            .clipShape(Capsule())
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
