import Combine
import SwiftUI

@MainActor
final class ThemeManager: ObservableObject {
    @Published var current: AppTheme

    static let allThemes: [AppTheme] = ThemeCatalog.allThemes

    private let userDefaults: UserDefaults
    private let selectedThemeIdKey = "selectedThemeId"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        current = Self.resolvedTheme(
            from: userDefaults.string(forKey: selectedThemeIdKey)
        )
    }

    func select(_ theme: AppTheme) {
        current = theme
        persist(themeID: theme.id)
    }
}

private extension ThemeManager {
    static func resolvedTheme(from storedThemeID: String?) -> AppTheme {
        if let storedThemeID,
           let storedTheme = allThemes.first(where: { $0.id == storedThemeID }) {
            return storedTheme
        }

        return ThemeCatalog.defaultTheme
    }

    func persist(themeID: String) {
        userDefaults.set(themeID, forKey: selectedThemeIdKey)
    }
}
