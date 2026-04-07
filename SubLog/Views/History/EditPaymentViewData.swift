import Foundation

struct EditPaymentViewData {
    let amountValue: Int
    let canSave: Bool
}

enum EditPaymentViewDataBuilder {
    static func build(amountText: String) -> EditPaymentViewData {
        let amountValue = Int(amountText) ?? 0
        return EditPaymentViewData(
            amountValue: amountValue,
            canSave: amountValue > 0
        )
    }

    static func normalizedOptionalText(_ text: String) -> String? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }
}
