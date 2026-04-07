import Foundation

struct EditSubscriptionViewData {
    let normalizedLabel: String
    let renewalInterval: RenewalInterval
    let priceValue: Int
    let startDate: Date
    let normalizedMemo: String?
    let canSave: Bool
}

enum EditSubscriptionViewDataBuilder {
    static func build(
        label: String,
        billingType: BillingType,
        renewalValueText: String,
        renewalUnit: RenewalIntervalUnit,
        priceText: String,
        startDate: Date,
        memo: String
    ) -> EditSubscriptionViewData {
        let normalizedLabel = label.trimmedText
        let renewalValue = positiveInt(from: renewalValueText)
        let priceValue = ViewDataCommon.intValue(from: priceText)

        return EditSubscriptionViewData(
            normalizedLabel: normalizedLabel,
            renewalInterval: RenewalInterval(value: renewalValue, unit: renewalUnit),
            priceValue: priceValue,
            startDate: startDate,
            normalizedMemo: memo.nilIfTrimmedEmpty,
            canSave: !normalizedLabel.isEmpty && priceValue > 0 && renewalValue > 0
        )
    }

    static func defaultInterval(for billingType: BillingType) -> RenewalInterval {
        billingType.defaultInterval
    }

    static func positiveInt(from text: String) -> Int {
        ViewDataCommon.intValue(from: text)
    }
}
