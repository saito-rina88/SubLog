import SwiftUI

struct ThemeItemData: Identifiable {
    let id: String
    let theme: AppTheme
    let isSelected: Bool
    let previewColors: [Color]
}

struct ThemeSelectViewData {
    let items: [ThemeItemData]
}

enum ThemeSelectViewDataBuilder {
    static func build(currentThemeID: String) -> ThemeSelectViewData {
        ThemeSelectViewData(
            items: ThemeManager.allThemes.map { appTheme in
                ThemeItemData(
                    id: appTheme.id,
                    theme: appTheme,
                    isSelected: appTheme.id == currentThemeID,
                    previewColors: [
                        appTheme.primary,
                        appTheme.primaryDark,
                        appTheme.primaryMid,
                        appTheme.primaryLight,
                        appTheme.primaryXLight
                    ]
                )
            }
        )
    }
}
