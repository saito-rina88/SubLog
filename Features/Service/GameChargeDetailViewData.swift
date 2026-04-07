import Foundation

enum PaymentField: Identifiable {
    case amount
    case type
    case date
    case memo

    var id: Self { self }
}

struct GameChargeDetailInfoRowData: Identifiable {
    let id: String
    let label: String
    let value: String
    let field: PaymentField
}

struct GameChargeDetailViewData {
    let serviceName: String
    let infoRows: [GameChargeDetailInfoRowData]
}

enum GameChargeDetailViewDataBuilder {
    static func build(payment: Payment) -> GameChargeDetailViewData {
        var rows: [GameChargeDetailInfoRowData] = [
            GameChargeDetailInfoRowData(
                id: "amount",
                label: "金額",
                value: ViewDataCommon.yenString(from: payment.amount),
                field: .amount
            ),
            GameChargeDetailInfoRowData(
                id: "type",
                label: "購入内容",
                value: payment.type.replacingOccurrences(of: "、", with: "\n"),
                field: .type
            ),
            GameChargeDetailInfoRowData(
                id: "date",
                label: "日付",
                value: dateString(payment.date),
                field: .date
            )
        ]

        if let memo = payment.memo, !memo.isEmpty {
            rows.append(
                GameChargeDetailInfoRowData(
                    id: "memo",
                    label: "メモ",
                    value: memo,
                    field: .memo
                )
            )
        }

        return GameChargeDetailViewData(
            serviceName: payment.service.name,
            infoRows: rows
        )
    }

    private static func dateString(_ date: Date) -> String {
        ViewDataCommon.slashDateString(from: date)
    }
}
