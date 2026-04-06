import StoreKit
import SwiftUI

struct SubscriptionManagementView: View {
    enum DisplayMode {
        case standard
        case serviceLimitReached
    }

    @EnvironmentObject private var entitlements: EntitlementManager
    @EnvironmentObject private var theme: ThemeManager
    @State private var isProcessing = false
    @State private var errorMessage: String?
    @State private var showInfoSheet = false

    private let displayMode: DisplayMode

    init(displayMode: DisplayMode = .standard) {
        self.displayMode = displayMode
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerSection
                    comparisonSection

                    if !entitlements.isPremium {
                        annualPlanCard
                            .padding(.top, 8)
                        monthlyPlanCard
                    }

                    restoreButton

                    if entitlements.isPremium {
                        manageSubscriptionSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, contentTopPadding)
                .padding(.bottom, 16)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(premiumTint)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showInfoSheet = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.system(size: 17, weight: .semibold))
                    }
                }
            }
            .overlay {
                if isProcessing {
                    ZStack {
                        Color.black.opacity(0.12)
                            .ignoresSafeArea()

                        ProgressView()
                            .padding(20)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                }
            }
            .alert("エラー", isPresented: errorPresented) {
                Button("OK", role: .cancel) {
                    errorMessage = nil
                }
            } message: {
                Text(errorMessage ?? "不明なエラーが発生しました。")
            }
            .alert("解約について", isPresented: $showInfoSheet) {
                Button("閉じる", role: .cancel) {}
            } message: {
                Text("サブスクリプションはいつでも解約できます。また、解約はApp Storeのアカウント設定から行えます。")
            }
        }
    }
}

private extension SubscriptionManagementView {
    var contentTopPadding: CGFloat {
        displayMode == .serviceLimitReached ? 18 : 0
    }

    var headerTopPadding: CGFloat {
        displayMode == .serviceLimitReached ? 12 : 0
    }

    var backgroundColor: Color {
        theme.current.primaryXLight
    }

    var premiumTint: Color {
        theme.current.primaryDeep
    }

    var premiumTintLight: Color {
        theme.current.primaryLight.opacity(0.9)
    }

    var surfaceColor: Color {
        Color.white
    }

    var premiumTintSoft: Color {
        theme.current.primaryDeep.opacity(0.72)
    }

    var premiumTintBorder: Color {
        theme.current.primary.opacity(0.58)
    }

    var premiumTintFill: Color {
        theme.current.primaryDeep.opacity(0.94)
    }

    var premiumTintSolidSoft: Color {
        theme.current.primary.opacity(0.9)
    }

    var errorPresented: Binding<Bool> {
        Binding(
            get: { errorMessage != nil },
            set: { newValue in
                if !newValue {
                    errorMessage = nil
                }
            }
        )
    }

    var headerTitle: String {
        entitlements.isPremium ? "プレミアムをご利用中です" : "プレミアムにアップグレード"
    }

    var headerSubtitle: String {
        if entitlements.isPremium {
            return "サービスを無制限に追加できます"
        }

        if displayMode == .serviceLimitReached {
            return "サービスの登録数を無制限に"
        }

        return "サービスの登録数を無制限に"
    }

    var headerSection: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(premiumTintSolidSoft)
                .frame(width: 54, height: 54)
                .overlay {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(spacing: 6) {
                Text(headerTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(premiumTint)
                    .multilineTextAlignment(.center)

                Text(headerSubtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(premiumTintSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, headerTopPadding)
    }

    var comparisonSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    comparisonHeaderCell("")
                    comparisonHeaderCell("無料")
                    comparisonHeaderCell("プレミアム", highlighted: true)
                }

                HStack(spacing: 0) {
                    comparisonValueCell("サービス登録上限", alignment: .leading)
                    comparisonValueCell("8件")
                    comparisonValueCell("無制限", highlighted: true)
                }
            }
            .background(Color.white)
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .stroke(premiumTintBorder.opacity(0.55), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(spacing: 6) {
                Text("※")
                    .font(.system(size: 12, weight: .bold))
                Text("サービス数は、定期支払い・単発支払いの合計です")
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(premiumTintSoft)
            .padding(.horizontal, 4)
        }
    }

    func comparisonHeaderCell(_ title: String, highlighted: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(highlighted ? Color.white : premiumTintSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(highlighted ? premiumTintFill : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(premiumTintBorder.opacity(0.55), lineWidth: 0.5)
            }
    }

    func comparisonValueCell(_ title: String, alignment: Alignment = .center, highlighted: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(highlighted ? premiumTint : premiumTintSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: alignment)
            .frame(height: 46)
            .padding(.horizontal, alignment == .leading ? 12 : 0)
            .background(highlighted ? premiumTintLight.opacity(0.45) : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(premiumTintBorder.opacity(0.55), lineWidth: 0.5)
            }
    }

    var annualPlanCard: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text("年額プラン")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(premiumTint)

                    Spacer()

                Text("約17% OFF")
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(premiumTint)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(premiumTintLight.opacity(0.95))
                    )
                    .padding(.top, 4)
            }

                HStack(alignment: .center) {
                    Text("¥1,200/年")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(premiumTintSoft)
                }

                Button {
                    Task {
                        await purchase(StoreKitConstants.ProductID.annual)
                    }
                } label: {
                    Text("年額プランで始める")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(premiumTintFill)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.55 : 1)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(surfaceColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(premiumTintBorder, lineWidth: 2)
            }
            .padding(.top, 8)

            ZStack {
                Capsule(style: .continuous)
                    .fill(backgroundColor)
                    .frame(width: 84, height: 34)

                Text("おすすめ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(premiumTint.opacity(0.82))
                    )
            }
            .offset(y: -8)
            .zIndex(1)
        }
    }

    var monthlyPlanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text("月額プラン")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(premiumTint)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("¥120")
                        .font(.system(size: 17, weight: .bold))
                    Text("/月")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(premiumTint)
            }

            Button {
                Task {
                    await purchase(StoreKitConstants.ProductID.monthly)
                }
            } label: {
                Text("月額プランで始める")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(premiumTint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(premiumTintBorder, lineWidth: 2)
                    }
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(surfaceColor)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(premiumTintBorder.opacity(0.6), lineWidth: 1)
        }
    }

    var restoreButton: some View {
        Button("購入を復元する") {
            Task {
                await restorePurchases()
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 17, weight: .bold))
        .foregroundStyle(premiumTintSoft)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.55 : 1)
    }

    var manageSubscriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("サブスクリプション管理")
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(premiumTint)

            Button("プランを解約する") {
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Text("解約はAppleのサブスクリプション管理画面から行えます")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(surfaceColor)
        )
    }

    func purchase(_ productID: String) async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            _ = try await entitlements.purchase(productID)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restorePurchases() async {
        isProcessing = true
        defer { isProcessing = false }

        do {
            try await entitlements.restorePurchases()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

#Preview {
    SubscriptionManagementView()
        .environmentObject(ThemeManager())
        .environmentObject(EntitlementManager())
}
