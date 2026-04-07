import SwiftUI

struct ServiceTypeCardDefinition {
    let id: String
    let title: String
    let iconName: String
    let recordSubtitle: String
    let managementSubtitle: String
}

struct ServiceTypeCardAppearance {
    let topColor: Color
    let iconColor: Color
    let borderColor: Color
}

enum ServiceTypeCardCatalog {
    static let displayOrder: [ServiceType] = [.subscription, .game]

    static func definition(for serviceType: ServiceType) -> ServiceTypeCardDefinition {
        switch serviceType {
        case .subscription:
            return ServiceTypeCardDefinition(
                id: "subscription",
                title: "定期支払い",
                iconName: "calendar.badge.clock",
                recordSubtitle: "月額・年額などの定期支払い",
                managementSubtitle: "サブスク系サービスを追加・編集・削除"
            )
        case .game:
            return ServiceTypeCardDefinition(
                id: "oneTime",
                title: "単発支払い",
                iconName: "creditcard.fill",
                recordSubtitle: "都度の支払い（買い切り・アイテム購入など）",
                managementSubtitle: "都度課金サービスを追加・編集・削除"
            )
        }
    }

    static func managementAppearance(for serviceType: ServiceType) -> ServiceTypeCardAppearance {
        switch serviceType {
        case .subscription:
            return ServiceTypeCardAppearance(
                topColor: Color(red: 0.84, green: 0.96, blue: 0.80),
                iconColor: Color(red: 0.29, green: 0.56, blue: 0.46),
                borderColor: Color(red: 0.84, green: 0.96, blue: 0.80)
            )
        case .game:
            return ServiceTypeCardAppearance(
                topColor: Color(red: 0.77, green: 0.97, blue: 0.92),
                iconColor: Color(red: 0.26, green: 0.59, blue: 0.53),
                borderColor: Color(red: 0.77, green: 0.97, blue: 0.92)
            )
        }
    }

    static func recordAppearance(for serviceType: ServiceType, theme: AppTheme) -> ServiceTypeCardAppearance {
        switch theme.id {
        case "green":
            switch serviceType {
            case .subscription:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.86, green: 0.95, blue: 0.72),
                    iconColor: Color(red: 0.41, green: 0.62, blue: 0.18),
                    borderColor: Color(red: 0.79, green: 0.89, blue: 0.56)
                )
            case .game:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.84, green: 0.96, blue: 0.80),
                    iconColor: Color(red: 0.29, green: 0.56, blue: 0.46),
                    borderColor: Color(red: 0.76, green: 0.90, blue: 0.72)
                )
            }
        case "purple":
            switch serviceType {
            case .subscription:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.92, green: 0.93, blue: 0.99),
                    iconColor: Color(red: 0.43, green: 0.49, blue: 0.79),
                    borderColor: Color(red: 0.82, green: 0.86, blue: 0.97)
                )
            case .game:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.92, green: 0.88, blue: 0.98),
                    iconColor: Color(red: 0.50, green: 0.31, blue: 0.72),
                    borderColor: Color(red: 0.84, green: 0.78, blue: 0.95)
                )
            }
        case "blue":
            switch serviceType {
            case .subscription:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.88, green: 0.95, blue: 0.99),
                    iconColor: Color(red: 0.31, green: 0.67, blue: 0.84),
                    borderColor: Color(red: 0.76, green: 0.88, blue: 0.96)
                )
            case .game:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.88, green: 0.92, blue: 0.99),
                    iconColor: Color(red: 0.28, green: 0.48, blue: 0.86),
                    borderColor: Color(red: 0.76, green: 0.84, blue: 0.97)
                )
            }
        case "pink":
            switch serviceType {
            case .subscription:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.99, green: 0.91, blue: 0.87),
                    iconColor: Color(red: 0.82, green: 0.47, blue: 0.38),
                    borderColor: Color(red: 0.96, green: 0.84, blue: 0.78)
                )
            case .game:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.98, green: 0.88, blue: 0.92),
                    iconColor: Color(red: 0.82, green: 0.36, blue: 0.54),
                    borderColor: Color(red: 0.95, green: 0.80, blue: 0.87)
                )
            }
        case "orange":
            switch serviceType {
            case .subscription:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.99, green: 0.95, blue: 0.77),
                    iconColor: Color(red: 0.78, green: 0.60, blue: 0.14),
                    borderColor: Color(red: 0.95, green: 0.88, blue: 0.62)
                )
            case .game:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.99, green: 0.91, blue: 0.82),
                    iconColor: Color(red: 0.86, green: 0.48, blue: 0.18),
                    borderColor: Color(red: 0.96, green: 0.83, blue: 0.69)
                )
            }
        case "mint":
            switch serviceType {
            case .subscription:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.84, green: 0.96, blue: 0.80),
                    iconColor: Color(red: 0.29, green: 0.56, blue: 0.46),
                    borderColor: Color(red: 0.78, green: 0.91, blue: 0.72)
                )
            case .game:
                return ServiceTypeCardAppearance(
                    topColor: Color(red: 0.77, green: 0.97, blue: 0.92),
                    iconColor: Color(red: 0.26, green: 0.59, blue: 0.53),
                    borderColor: Color(red: 0.70, green: 0.90, blue: 0.84)
                )
            }
        default:
            return managementAppearance(for: serviceType)
        }
    }
}
