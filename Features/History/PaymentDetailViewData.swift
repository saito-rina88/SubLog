import Foundation
import UIKit

struct PaymentDetailViewData {
    let serviceName: String
    let categoryName: String
    let amountText: String
    let paymentTypeText: String
    let dateText: String
    let memoText: String?
    let screenshotImage: UIImage?
}

enum PaymentDetailViewDataBuilder {
    static func build(payment: Payment) -> PaymentDetailViewData {
        PaymentDetailViewData(
            serviceName: payment.service.name,
            categoryName: payment.service.category.displayName,
            amountText: ViewDataCommon.yenString(from: payment.amount),
            paymentTypeText: payment.type.replacingOccurrences(of: "、", with: "\n"),
            dateText: payment.date.formatted(detailDateFormat),
            memoText: payment.memo,
            screenshotImage: payment.screenshotData.flatMap { UIImage(data: $0) }
        )
    }

    private static var detailDateFormat: Date.FormatStyle {
        Date.FormatStyle()
            .year(.defaultDigits)
            .month(.twoDigits)
            .day(.twoDigits)
    }
}
