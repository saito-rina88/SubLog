import SwiftUI
import SwiftData
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var theme: ThemeManager
    @Query private var services: [Service]

    @State private var showExportAlert = false
    @State private var showDeleteConfirmation = false
    @State private var showFinalDeleteConfirmation = false
    @State private var showSubscriptionManagement = false

    var body: some View {
        NavigationStack {
            List {
                Section {
                    premiumBanner
                }
                .listRowInsets(EdgeInsets(top: 8, leading: 8, bottom: 0, trailing: 8))
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)

                Section(
                    header: Text("カスタマイズ")
                        .foregroundStyle(theme.current.primaryDeep)
                ) {
                    NavigationLink("サービス一覧の編集") {
                        ServiceListView(managementMode: true)
                    }

                    NavigationLink("利用中のサブスク") {
                        ActiveSubscriptionsView()
                    }

                    NavigationLink("購入内容テンプレート") {
                        GachaTemplateSettingsView()
                    }

                    NavigationLink("カラーテーマ") {
                        ThemeSelectView()
                    }
                }

                Section(
                    header: Text("データ")
                        .foregroundStyle(theme.current.primaryDeep)
                ) {
                    Button("データエクスポート") {
                        showExportAlert = true
                    }

                    Button("データをすべて削除", role: .destructive) {
                        showDeleteConfirmation = true
                    }
                }

                Section(
                    header: Text("ヘルプ")
                        .foregroundStyle(theme.current.primaryDeep)
                ) {
                    NavigationLink("購入内容テンプレートについて") {
                        EmptyView()
                    }

                    NavigationLink("プレミアムプランの解約方法について") {
                        EmptyView()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .listSectionSpacing(.compact)
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(theme.current.primaryXLight.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(isPresented: $showSubscriptionManagement) {
                SubscriptionManagementView()
            }
            .tint(theme.current.primary)
            .alert("近日対応予定", isPresented: $showExportAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("データエクスポートは近日対応予定です。")
            }
            .alert("本当に削除しますか？この操作は取り消せません", isPresented: $showDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("次へ", role: .destructive) {
                    showFinalDeleteConfirmation = true
                }
            }
            .alert("データをすべて削除", isPresented: $showFinalDeleteConfirmation) {
                Button("キャンセル", role: .cancel) {}
                Button("削除する", role: .destructive) {
                    deleteAllServices()
                }
            } message: {
                Text("保存されているサービスと関連データをすべて削除します。")
            }
        }
    }
}

private extension SettingsView {
    var premiumBannerBrightColor: Color {
        entitlements.isPremium ? theme.current.primaryDark : theme.current.primary
    }

    var premiumBannerDarkColor: Color {
        theme.current.primaryDark
    }

    var premiumBanner: some View {
        Button {
            showSubscriptionManagement = true
        } label: {
            HStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                Color(red: 255 / 255, green: 246 / 255, blue: 196 / 255),
                                Color(red: 232 / 255, green: 192 / 255, blue: 79 / 255),
                                Color(red: 184 / 255, green: 134 / 255, blue: 11 / 255),
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .shadow(color: Color.white.opacity(0.35), radius: 2, y: -1)
                    .frame(width: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text(entitlements.isPremium ? "プレミアム会員" : "プレミアムにアップグレード")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(entitlements.isPremium ? "サービス登録数が無制限です" : "サービスを無制限に登録できます")
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.85))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                Text(entitlements.isPremium ? "管理する" : "詳しく見る >")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(.white.opacity(0.25))
                    .cornerRadius(20)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(.white.opacity(0.6), lineWidth: 1)
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 22)
            .background(premiumBannerBrightColor)
            .cornerRadius(16)
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
        .padding(.top, 12)
        .padding(.bottom, 0)
    }

    func deleteAllServices() {
        services.forEach { service in
            modelContext.delete(service)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(EntitlementManager())
        .environmentObject(ThemeManager())
}
