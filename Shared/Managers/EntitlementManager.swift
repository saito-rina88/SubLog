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
                guard let transaction = EntitlementStoreKitSupport.verifiedTransaction(from: update) else {
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
        isPremium = await EntitlementStoreKitSupport.hasPremiumEntitlement(
            validProductIDs: StoreKitConstants.ProductID.all
        )
    }

    func purchase(_ productID: String) async throws -> Bool {
        let product = try await EntitlementStoreKitSupport.loadProduct(productID)

        let result = try await product.purchase()

        switch result {
        case .success(let verificationResult):
            let transaction = try EntitlementStoreKitSupport.requireVerifiedTransaction(from: verificationResult)
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
