import Foundation

enum MessageCatalog {
    static let paymentDeleteTitle = "支払いを削除しますか？"
    static let serviceDeleteTitle = "サービスを削除しますか？"
    static let templateDeleteTitle = "テンプレートを削除しますか？"

    static let operationCannotBeUndone = "この操作は取り消せません。"
    static let serviceDeleteDescription = "支払い履歴は残り、サービス一覧からのみ外れます。サブスクは停止扱いになります。"
    static let templateMissingDescription = "このサービスにはテンプレートがありません。設定から追加してください。"

    static func reminderSummary(daysBefore: Int) -> String {
        "\(daysBefore)日前と当日に通知します"
    }
}
