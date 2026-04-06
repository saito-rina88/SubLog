enum BillingType: String, CaseIterable, Codable {
    case weekly   = "ウィークリー"
    case monthly  = "マンスリー"
    case seasonal = "シーズンパス"
    case annual   = "年額"

    var displayName: String { rawValue }

    /// UI表示用：標準的な周期の説明
    var intervalDescription: String {
        switch self {
        case .weekly:   return "毎週"
        case .monthly:  return "毎月"
        case .seasonal: return "シーズンごと（カスタム）"
        case .annual:   return "毎年"
        }
    }

    /// Subscription 作成時の renewalInterval 初期値
    var defaultInterval: RenewalInterval {
        switch self {
        case .weekly:   return RenewalInterval(value: 7,  unit: .day)
        case .monthly:  return RenewalInterval(value: 1,  unit: .month)
        case .seasonal: return RenewalInterval(value: 90, unit: .day)
        case .annual:   return RenewalInterval(value: 1,  unit: .year)
        }
    }

    /// seasonal のときのみ周期入力UIを表示するフラグ
    var requiresCustomInterval: Bool {
        return self == .seasonal
    }
}
