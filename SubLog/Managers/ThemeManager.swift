import Combine
import SwiftUI

struct AppTheme: Identifiable, Equatable {
    let id: String
    let name: String
    let primary: Color
    let primaryDark: Color
    let primaryDeep: Color
    let primaryMid: Color
    let primaryLight: Color
    let primaryXLight: Color
}

@MainActor
final class ThemeManager: ObservableObject {
    @Published var current: AppTheme

    static let allThemes: [AppTheme] = [
        AppTheme(
            id: "mint",
            name: "Mint",
            primary: Color(hex: 0x3DBDA8),
            primaryDark: Color(hex: 0x1A9E8A),
            primaryDeep: Color(hex: 0x107060),
            primaryMid: Color(hex: 0x2BBFAA),
            primaryLight: Color(hex: 0xE0F5F2),
            primaryXLight: Color(hex: 0xF0FAF9)
        ),
        AppTheme(
            id: "green",
            name: "Green",
            primary: Color(hex: 0x52C97D),
            primaryDark: Color(hex: 0x2EA055),
            primaryDeep: Color(hex: 0x1A6B35),
            primaryMid: Color(hex: 0x3DC96D),
            primaryLight: Color(hex: 0xE0F5E8),
            primaryXLight: Color(hex: 0xF0FAF3)
        ),
        AppTheme(
            id: "pink",
            name: "Pink",
            primary: Color(hex: 0xF07099),
            primaryDark: Color(hex: 0xC83A6A),
            primaryDeep: Color(hex: 0x8C1A42),
            primaryMid: Color(hex: 0xE85585),
            primaryLight: Color(hex: 0xFAE0EB),
            primaryXLight: Color(hex: 0xFDF0F5)
        ),
        AppTheme(
            id: "blue",
            name: "Blue",
            primary: Color(hex: 0x5B9EEF),
            primaryDark: Color(hex: 0x2E68D4),
            primaryDeep: Color(hex: 0x1040A0),
            primaryMid: Color(hex: 0x4A8AE0),
            primaryLight: Color(hex: 0xE0ECFA),
            primaryXLight: Color(hex: 0xF0F5FD)
        ),
        AppTheme(
            id: "purple",
            name: "Purple",
            primary: Color(hex: 0x9B72CF),
            primaryDark: Color(hex: 0x6A3EAF),
            primaryDeep: Color(hex: 0x401880),
            primaryMid: Color(hex: 0x8860C0),
            primaryLight: Color(hex: 0xEDE0FA),
            primaryXLight: Color(hex: 0xF6F0FD)
        ),
        AppTheme(
            id: "orange",
            name: "Orange",
            primary: Color(hex: 0xF5914A),
            primaryDark: Color(hex: 0xCC6018),
            primaryDeep: Color(hex: 0x8C3A08),
            primaryMid: Color(hex: 0xE07830),
            primaryLight: Color(hex: 0xFAF0E0),
            primaryXLight: Color(hex: 0xFDF8F0)
        )
    ]

    private let userDefaults: UserDefaults
    private let selectedThemeIdKey = "selectedThemeId"

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        if let storedThemeId = userDefaults.string(forKey: selectedThemeIdKey),
           let storedTheme = Self.allThemes.first(where: { $0.id == storedThemeId }) {
            current = storedTheme
        } else {
            current = Self.allThemes.first(where: { $0.id == "mint" }) ?? Self.allThemes[0]
        }
    }

    func select(_ theme: AppTheme) {
        current = theme
        userDefaults.set(theme.id, forKey: selectedThemeIdKey)
    }
}

private extension Color {
    init(hex: Int) {
        let red = Double((hex >> 16) & 0xFF) / 255
        let green = Double((hex >> 8) & 0xFF) / 255
        let blue = Double(hex & 0xFF) / 255

        self.init(red: red, green: green, blue: blue)
    }
}
