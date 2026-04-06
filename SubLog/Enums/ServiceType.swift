enum ServiceType: String, CaseIterable, Codable {
    case game         = "ゲーム課金"
    case subscription = "サブスク"

    var displayName: String { rawValue }
}
