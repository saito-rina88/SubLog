import Combine
import StoreKit

@MainActor
final class EntitlementManager: ObservableObject {
    @Published var isPremium: Bool = false

    private var transactionUpdatesTask: Task<Void, Never>?

    init() {
        transactionUpdatesTask = Task { [weak self] in
            guard let self else { return }

            for await update in Transaction.updates {
                guard case .verified(let transaction) = update else {
                    continue
                }

                await transaction.finish()
                await self.updatePurchasedProducts()
            }
        }
    }

    deinit {
        transactionUpdatesTask?.cancel()
    }

    func updatePurchasedProducts() async {
        var hasPremium = false

        for await entitlement in Transaction.currentEntitlements {
            guard case .verified(let transaction) = entitlement else {
                continue
            }

            guard StoreKitConstants.ProductID.all.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }

            hasPremium = true
            break
        }

        isPremium = hasPremium
    }

    func purchase(_ productID: String) async throws -> Bool {
        let products = try await Product.products(for: [productID])

        guard let product = products.first else {
            throw EntitlementError.productNotFound(productID)
        }

        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            let transaction = try verifiedTransaction(from: verificationResult)
            await transaction.finish()
            await updatePurchasedProducts()
            return isPremium
        case .userCancelled, .pending:
            return false
        @unknown default:
            return false
        }
    }

    func restorePurchases() async throws {
        try await AppStore.sync()
        await updatePurchasedProducts()
    }
}

extension EntitlementManager {
    func canAddService(currentCount: Int) -> Bool {
        isPremium || currentCount < 8
    }

    func canAddGachaTemplate(totalCount: Int) -> Bool {
        true
    }

    func canAttachScreenshot() -> Bool { true }
    func canViewAdvancedAnalytics() -> Bool { true }
    func canExportData() -> Bool { true }
    func canUseReminder() -> Bool { true }
}

private extension EntitlementManager {
    enum EntitlementError: LocalizedError {
        case failedVerification
        case productNotFound(String)

        var errorDescription: String? {
            switch self {
            case .failedVerification:
                return "購入情報の検証に失敗しました。"
            case .productNotFound(let productID):
                return "商品が見つかりません: \(productID)"
            }
        }
    }

    func verifiedTransaction(from result: VerificationResult<Transaction>) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw EntitlementError.failedVerification
        }
    }
}
