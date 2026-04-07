import SwiftUI

struct SubscriptionManagementPalette {
    let backgroundColor: Color
    let premiumTint: Color
    let premiumTintLight: Color
    let surfaceColor: Color
    let premiumTintSoft: Color
    let premiumTintBorder: Color
    let premiumTintFill: Color
    let premiumTintSolidSoft: Color
}

struct SubscriptionManagementDisplayState {
    let contentTopPadding: CGFloat
    let headerTopPadding: CGFloat
    let headerTitle: String
    let headerSubtitle: String
    let comparisonFootnote: String
    let infoTitle: String
    let infoMessage: String
    let restoreButtonTitle: String
    let manageTitle: String
    let manageButtonTitle: String
    let manageCaption: String
    let shouldShowPlans: Bool
    let shouldShowManageSection: Bool
}

struct SubscriptionPlanItem {
    let title: String
    let priceText: String
    let ctaTitle: String
    let productID: String
    let badgeText: String?
    let isRecommended: Bool
}

enum SubscriptionManagementViewDataBuilder {
    static func makePalette(theme: AppTheme) -> SubscriptionManagementPalette {
        SubscriptionManagementPalette(
            backgroundColor: theme.primaryXLight,
            premiumTint: theme.primaryDeep,
            premiumTintLight: theme.primaryLight.opacity(0.9),
            surfaceColor: .white,
            premiumTintSoft: theme.primaryDeep.opacity(0.72),
            premiumTintBorder: theme.primary.opacity(0.58),
            premiumTintFill: theme.primaryDeep.opacity(0.94),
            premiumTintSolidSoft: theme.primary.opacity(0.9)
        )
    }

    static func makeDisplayState(
        isPremium: Bool,
        displayMode: SubscriptionManagementView.DisplayMode
    ) -> SubscriptionManagementDisplayState {
        SubscriptionManagementDisplayState(
            contentTopPadding: displayMode == .serviceLimitReached ? 18 : 0,
            headerTopPadding: displayMode == .serviceLimitReached ? 12 : 0,
            headerTitle: isPremium ? "プレミアムをご利用中です" : "プレミアムにアップグレード",
            headerSubtitle: "サービスの登録数を無制限に",
            comparisonFootnote: "サービス数は、定期支払い・単発支払いの合計です",
            infoTitle: "解約について",
            infoMessage: "サブスクリプションはいつでも解約できます。また、解約はApp Storeのアカウント設定から行えます。",
            restoreButtonTitle: "購入を復元する",
            manageTitle: "サブスクリプション管理",
            manageButtonTitle: "プランを解約する",
            manageCaption: "解約はAppleのサブスクリプション管理画面から行えます",
            shouldShowPlans: !isPremium,
            shouldShowManageSection: isPremium
        )
    }

    static func annualPlan() -> SubscriptionPlanItem {
        SubscriptionPlanItem(
            title: "年額プラン",
            priceText: "¥1,200/年",
            ctaTitle: "年額プランで始める",
            productID: StoreKitConstants.ProductID.annual,
            badgeText: "約17% OFF",
            isRecommended: true
        )
    }

    static func monthlyPlan() -> SubscriptionPlanItem {
        SubscriptionPlanItem(
            title: "月額プラン",
            priceText: "¥120/月",
            ctaTitle: "月額プランで始める",
            productID: StoreKitConstants.ProductID.monthly,
            badgeText: nil,
            isRecommended: false
        )
    }
}
