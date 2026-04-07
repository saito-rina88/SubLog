import StoreKit

enum EntitlementStoreKitError: LocalizedError {
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

enum EntitlementStoreKitSupport {
    static func hasPremiumEntitlement(validProductIDs: [String]) async -> Bool {
        for await entitlement in Transaction.currentEntitlements {
            guard let transaction = verifiedTransaction(from: entitlement) else {
                continue
            }

            guard validProductIDs.contains(transaction.productID),
                  transaction.revocationDate == nil else {
                continue
            }

            return true
        }

        return false
    }

    static func loadProduct(_ productID: String) async throws -> Product {
        let products = try await Product.products(for: [productID])

        guard let product = products.first else {
            throw EntitlementStoreKitError.productNotFound(productID)
        }

        return product
    }

    static func requireVerifiedTransaction(
        from result: VerificationResult<Transaction>
    ) throws -> Transaction {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            throw EntitlementStoreKitError.failedVerification
        }
    }

    static func verifiedTransaction(
        from result: VerificationResult<Transaction>
    ) -> Transaction? {
        switch result {
        case .verified(let transaction):
            return transaction
        case .unverified:
            return nil
        }
    }
}
