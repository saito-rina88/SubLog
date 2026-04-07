import SwiftUI

struct SettingsSectionItem: Identifiable {
    enum Destination {
        case serviceListManagement
        case activeSubscriptions
        case gachaTemplateSettings
        case themeSelect
        case helpPurchaseTemplate
        case helpPremiumCancellation
    }

    enum Action {
        case exportData
        case deleteAllData
    }

    let id: String
    let title: String
    let destination: Destination?
    let action: Action?

    init(id: String, title: String, destination: Destination) {
        self.id = id
        self.title = title
        self.destination = destination
        self.action = nil
    }

    init(id: String, title: String, action: Action) {
        self.id = id
        self.title = title
        self.destination = nil
        self.action = action
    }
}

struct SettingsSectionData: Identifiable {
    let title: String
    let items: [SettingsSectionItem]

    var id: String { title }
}

struct SettingsPremiumBannerState {
    let title: String
    let subtitle: String
    let buttonTitle: String
    let backgroundColor: Color
}

enum SettingsViewDataBuilder {
    static func makeSections() -> [SettingsSectionData] {
        [
            SettingsSectionData(
                title: "カスタマイズ",
                items: [
                    SettingsSectionItem(id: "service_list", title: "サービス一覧の編集", destination: .serviceListManagement),
                    SettingsSectionItem(id: "active_subscriptions", title: "利用中のサブスク", destination: .activeSubscriptions),
                    SettingsSectionItem(id: "gacha_templates", title: "購入内容テンプレート", destination: .gachaTemplateSettings),
                    SettingsSectionItem(id: "theme_select", title: "カラーテーマ", destination: .themeSelect),
                ]
            ),
            SettingsSectionData(
                title: "データ",
                items: [
                    SettingsSectionItem(id: "export_data", title: "データエクスポート", action: .exportData),
                    SettingsSectionItem(id: "delete_all", title: "データをすべて削除", action: .deleteAllData),
                ]
            ),
            SettingsSectionData(
                title: "ヘルプ",
                items: [
                    SettingsSectionItem(id: "help_purchase_template", title: "購入内容テンプレートについて", destination: .helpPurchaseTemplate),
                    SettingsSectionItem(id: "help_premium_cancellation", title: "プレミアムプランの解約方法について", destination: .helpPremiumCancellation),
                ]
            ),
        ]
    }

    static func premiumBannerState(isPremium: Bool, theme: AppTheme) -> SettingsPremiumBannerState {
        SettingsPremiumBannerState(
            title: isPremium ? "プレミアム会員" : "プレミアムにアップグレード",
            subtitle: isPremium ? "サービス登録数が無制限です" : "サービスを無制限に登録できます",
            buttonTitle: isPremium ? "管理する" : "詳しく見る >",
            backgroundColor: isPremium ? theme.primaryDark : theme.primary
        )
    }
}
