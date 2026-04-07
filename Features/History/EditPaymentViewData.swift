import Foundation

struct EditPaymentViewData {
    let amountValue: Int
    let canSave: Bool
}

enum EditPaymentViewDataBuilder {
    static func build(amountText: String) -> EditPaymentViewData {
        let amountValue = ViewDataCommon.intValue(from: amountText)
        return EditPaymentViewData(
            amountValue: amountValue,
            canSave: amountValue > 0
        )
    }

    static func normalizedOptionalText(_ text: String) -> String? {
        text.nilIfTrimmedEmpty
    }
}
