import SwiftUI

enum Category: String, CaseIterable, Codable {
    case game         = "ゲーム"
    case music        = "音楽"
    case video        = "動画"
    case book         = "書籍"
    case ai           = "AI"
    case sports       = "スポーツ"
    case other        = "その他"

    var displayName: String { rawValue }

    var sfSymbol: String {
        switch self {
        case .game:   return "gamecontroller.fill"
        case .music:  return "music.note"
        case .video:  return "play.tv.fill"
        case .book:   return "book.fill"
        case .ai:     return "sparkles"
        case .sports: return "figure.run"
        case .other:  return "square.grid.2x2.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .game:   return .orange
        case .music:  return .green
        case .video:  return .red
        case .book:   return .blue
        case .ai:     return .purple
        case .sports: return .teal
        case .other:  return .gray
        }
    }

    var presetSymbolPointSize: CGFloat {
        switch self {
        case .game:   return 122
        case .music:  return 128
        case .book:   return 122
        case .video:  return 108
        case .ai:     return 108
        case .sports: return 108
        case .other:  return 108
        }
    }

    var generatedSymbolFrame: CGSize {
        switch self {
        case .game:
            return CGSize(width: 116, height: 84)
        case .music:
            return CGSize(width: 86, height: 112)
        case .book:
            return CGSize(width: 92, height: 112)
        default:
            return CGSize(width: 104, height: 104)
        }
    }

    var generatedSymbolYOffset: CGFloat {
        switch self {
        case .game:
            return 2
        default:
            return 0
        }
    }
}
