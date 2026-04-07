import Foundation

enum RenewalIntervalUnit: String, CaseIterable, Codable {
    case day   = "日"
    case week  = "週"
    case month = "ヶ月"
    case year  = "年"

    var displayName: String { rawValue }

    var calendarComponent: Calendar.Component {
        switch self {
        case .day:   return .day
        case .week:  return .weekOfYear
        case .month: return .month
        case .year:  return .year
        }
    }
}

/// Subscription に埋め込む周期値型
/// SwiftData の Codable 埋め込みとして使用
struct RenewalInterval: Codable, Equatable {
    var value: Int
    var unit: RenewalIntervalUnit

    /// UI表示用：例 "42日"、"3ヶ月"
    var displayText: String {
        "\(value)\(unit.rawValue)"
    }
}
