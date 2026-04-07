import SwiftUI
import SwiftData

struct RootTabView: View {
    private enum Tab: Hashable {
        case home
        case history
        case record
        case analytics
        case settings
    }

    @EnvironmentObject private var theme: ThemeManager
    @State private var selectedTab: Tab = .home
    @State private var homeResetToken = 0
    @State private var historyResetToken = 0
    @State private var recordResetToken = 0
    @State private var analyticsResetToken = 0
    @State private var settingsResetToken = 0

    init() {
        UITabBar.appearance().isHidden = true
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .id(homeResetToken)
                .tag(Tab.home)

            HistoryView()
                .id(historyResetToken)
                .tag(Tab.history)

            RecordView()
                .id(recordResetToken)
                .tag(Tab.record)

            AnalyticsView()
                .id(analyticsResetToken)
                .tag(Tab.analytics)

            SettingsView()
                .id(settingsResetToken)
                .tag(Tab.settings)
        }
        .toolbar(.hidden, for: .tabBar)
        .overlay(alignment: .bottom) {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Spacer()
                    floatingTabBar(bottomInset: proxy.safeAreaInsets.bottom)
                }
                .ignoresSafeArea(edges: .bottom)
            }
        }
    }
}

private extension RootTabView {
    var tabBarBackgroundColor: Color {
        Color(uiColor: .systemBackground)
    }

    func floatingTabBar(bottomInset: CGFloat) -> some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                tabButton(.home, title: "ホーム", systemImage: "house.fill")
                tabButton(.history, title: "履歴", systemImage: "rectangle.stack.fill")
                tabButton(.record, title: "記録", systemImage: "plus.circle.fill")
                tabButton(.analytics, title: "分析", systemImage: "chart.pie.fill")
                tabButton(.settings, title: "設定", systemImage: "gearshape.fill")
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 6)
            .padding(.bottom, 8)

            tabBarBackgroundColor
                .frame(height: bottomInset)
        }
        .background(
            tabBarBackgroundColor
                .shadow(color: Color.black.opacity(0.10), radius: 16, y: -2)
        )
    }

    private func tabButton(_ tab: Tab, title: String, systemImage: String) -> some View {
        let isSelected = selectedTab == tab

        return Button {
            if isSelected {
                reset(tab)
            } else {
                selectedTab = tab
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.system(size: tab == .record ? 20 : 19, weight: .semibold))
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .lineLimit(1)
            }
            .padding(.top, 15)
            .foregroundStyle(isSelected ? Color(theme.current.primary) : Color(red: 150 / 255, green: 156 / 255, blue: 176 / 255))
            .frame(maxWidth: .infinity)
            .frame(height: 42)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func reset(_ tab: Tab) {
        switch tab {
        case .home:
            homeResetToken += 1
        case .history:
            historyResetToken += 1
        case .record:
            recordResetToken += 1
        case .analytics:
            analyticsResetToken += 1
        case .settings:
            settingsResetToken += 1
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(EntitlementManager())
        .environmentObject(NotificationManager())
        .environmentObject(ThemeManager())
        .modelContainer(
            try! ModelContainer(
                for: Service.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
}
