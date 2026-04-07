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

    private var palette: SubscriptionManagementPalette {
        SubscriptionManagementViewDataBuilder.makePalette(theme: theme.current)
    }

    private var displayState: SubscriptionManagementDisplayState {
        SubscriptionManagementViewDataBuilder.makeDisplayState(
            isPremium: entitlements.isPremium,
            displayMode: displayMode
        )
    }

    private let annualPlan = SubscriptionManagementViewDataBuilder.annualPlan()
    private let monthlyPlan = SubscriptionManagementViewDataBuilder.monthlyPlan()

    init(displayMode: DisplayMode = .standard) {
        self.displayMode = displayMode
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 18) {
                    headerSection
                    comparisonSection

                    if displayState.shouldShowPlans {
                        annualPlanCard
                            .padding(.top, 8)
                        monthlyPlanCard
                    }

                    restoreButton

                    if displayState.shouldShowManageSection {
                        manageSubscriptionSection
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, displayState.contentTopPadding)
                .padding(.bottom, 16)
                .frame(maxWidth: 520)
                .frame(maxWidth: .infinity)
            }
            .safeAreaInset(edge: .bottom) {
                Color.clear
                    .frame(height: 56)
            }
            .background(palette.backgroundColor.ignoresSafeArea())
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .tint(palette.premiumTint)
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
                Text(displayState.infoMessage)
            }
        }
    }
}

private extension SubscriptionManagementView {
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

    var headerSection: some View {
        VStack(spacing: 14) {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(palette.premiumTintSolidSoft)
                .frame(width: 54, height: 54)
                .overlay {
                    Image(systemName: "crown.fill")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(.white)
                }

            VStack(spacing: 6) {
                Text(displayState.headerTitle)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundStyle(palette.premiumTint)
                    .multilineTextAlignment(.center)

                Text(displayState.headerSubtitle)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(palette.premiumTintSoft)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.top, displayState.headerTopPadding)
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
                    .stroke(palette.premiumTintBorder.opacity(0.55), lineWidth: 1)
            }
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

            HStack(spacing: 6) {
                Text("※")
                    .font(.system(size: 12, weight: .bold))
                Text(displayState.comparisonFootnote)
                    .font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(palette.premiumTintSoft)
            .padding(.horizontal, 4)
        }
    }

    func comparisonHeaderCell(_ title: String, highlighted: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(highlighted ? Color.white : palette.premiumTintSoft)
            .frame(maxWidth: .infinity)
            .frame(height: 40)
            .background(highlighted ? palette.premiumTintFill : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(palette.premiumTintBorder.opacity(0.55), lineWidth: 0.5)
            }
    }

    func comparisonValueCell(_ title: String, alignment: Alignment = .center, highlighted: Bool = false) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .bold))
            .foregroundStyle(highlighted ? palette.premiumTint : palette.premiumTintSoft)
            .lineLimit(1)
            .minimumScaleFactor(0.85)
            .frame(maxWidth: .infinity, alignment: alignment)
            .frame(height: 46)
            .padding(.horizontal, alignment == .leading ? 12 : 0)
            .background(highlighted ? palette.premiumTintLight.opacity(0.45) : Color.clear)
            .overlay {
                Rectangle()
                    .stroke(palette.premiumTintBorder.opacity(0.55), lineWidth: 0.5)
            }
    }

    var annualPlanCard: some View {
        ZStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 14) {
                HStack(alignment: .top) {
                    Text(annualPlan.title)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(palette.premiumTint)

                    Spacer()

                if let badgeText = annualPlan.badgeText {
                    Text(badgeText)
                    .font(.system(size: 15, weight: .heavy))
                    .foregroundStyle(palette.premiumTint)
                    .padding(.horizontal, 13)
                    .padding(.vertical, 8)
                    .background(
                        Capsule(style: .continuous)
                            .fill(palette.premiumTintLight.opacity(0.95))
                    )
                    .padding(.top, 4)
                }
            }

                HStack(alignment: .center) {
                    Text(annualPlan.priceText)
                        .font(.system(size: 26, weight: .bold))
                        .foregroundStyle(palette.premiumTintSoft)
                }

                Button {
                    Task {
                        await purchase(annualPlan.productID)
                    }
                } label: {
                    Text(annualPlan.ctaTitle)
                        .font(.system(size: 17, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(palette.premiumTintFill)
                        )
                }
                .buttonStyle(.plain)
                .disabled(isProcessing)
                .opacity(isProcessing ? 0.55 : 1)
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(palette.surfaceColor)
            )
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(palette.premiumTintBorder, lineWidth: 2)
            }
            .padding(.top, 8)

            ZStack {
                Capsule(style: .continuous)
                    .fill(palette.backgroundColor)
                    .frame(width: 84, height: 34)

                Text("おすすめ")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(
                        Capsule(style: .continuous)
                            .fill(palette.premiumTint.opacity(0.82))
                    )
            }
            .offset(y: -8)
            .zIndex(1)
        }
    }

    var monthlyPlanCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 10) {
                Text(monthlyPlan.title)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.premiumTint)

                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text("¥120")
                        .font(.system(size: 17, weight: .bold))
                    Text("/月")
                        .font(.system(size: 13, weight: .bold))
                }
                .foregroundStyle(palette.premiumTint)
            }

            Button {
                Task {
                    await purchase(monthlyPlan.productID)
                }
            } label: {
                Text(monthlyPlan.ctaTitle)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(palette.premiumTint)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(.white)
                    )
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(palette.premiumTintBorder, lineWidth: 2)
                    }
            }
            .buttonStyle(.plain)
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.55 : 1)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.surfaceColor)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(palette.premiumTintBorder.opacity(0.6), lineWidth: 1)
        }
    }

    var restoreButton: some View {
        Button(displayState.restoreButtonTitle) {
            Task {
                await restorePurchases()
            }
        }
        .buttonStyle(.plain)
        .font(.system(size: 17, weight: .bold))
        .foregroundStyle(palette.premiumTintSoft)
        .frame(maxWidth: .infinity)
        .padding(.top, 6)
        .disabled(isProcessing)
        .opacity(isProcessing ? 0.55 : 1)
    }

    var manageSubscriptionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(displayState.manageTitle)
                .font(.system(size: 16, weight: .bold))
                .foregroundStyle(palette.premiumTint)

            Button(displayState.manageButtonTitle) {
                if let url = URL(string: "itms-apps://apps.apple.com/account/subscriptions") {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.bordered)
            .tint(.red)

            Text(displayState.manageCaption)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(palette.surfaceColor)
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
