//
//  Store.swift
//  StoreKitPlay
//
//  Created by Kamaal M Farah on 18/04/2022.
//

import Foundation
import StoreKit

final class Store: ObservableObject {

    @Published private(set) var cars: [StoreProduct] = []
    @Published private(set) var fuel: [StoreProduct] = []
    @Published var isLoading = false
    @Published private(set) var purchasedIdentifiers = Set<String>()

    private var updateListenerTask: Task<Void, Error>?
    private let productsMap: [String: String]

    init() {
        self.productsMap = Self.getInitialProductsMap()

        self.updateListenerTask = listenForTransactions()
    }

    deinit {
        updateListenerTask?.cancel()
    }

    enum Errors: Error {
        case failedVerification
    }

    @MainActor
    func requestProducts() async {
        await withLoading(completion: {
            let storeProducts: [Product]
            do {
                storeProducts = try await Product.products(for: productsMap.keys)
            } catch {
                print("failed product request: \(error)")
                return
            }

            var cars: [StoreProduct] = []
            var fuel: [StoreProduct] = []
            for product in storeProducts {
                let isPurchased = await self.isPurchased(product.id)
                let emoji = productsMap[product.id] ?? "?"
                let customProduct = product.toStoreProduct(emoji: emoji, isPurchased: isPurchased)
                switch product.type {
                case .nonConsumable: cars.append(customProduct)
                case .consumable: fuel.append(customProduct)
                default: continue
                }
            }

            self.cars = cars
            self.fuel = fuel
        })
    }

    func purchase(_ product: StoreProduct) async -> Transaction? {
        let result: Product.PurchaseResult
        do {
            result = try await product.info.purchase()
        } catch {
            print("failed to purchase product \(error)")
            return nil
        }

        let verification: (VerificationResult<Transaction>)
        switch result {
        case .pending, .userCancelled: return nil
        case .success(let success): verification = success
        default: return nil
        }

        let transaction: Transaction
        let transactionResult = checkVerified(verification)
        switch transactionResult {
        case .failure(let failure):
            print("transaction could not be verified \(failure)")
            return nil
        case .success(let success): transaction = success
        }

        await updatePurchasedIdentifiers(transaction)

        await transaction.finish()

        return transaction
    }

    private func isPurchased(_ productIdentifier: String) async -> Bool {
        // Get the most recent transaction receipt for this `productIdentifier`.
        guard let result = await Transaction.latest(for: productIdentifier) else { return false }

        let transaction: Transaction
        let transactionResult = checkVerified(result)
        switch transactionResult {
        case .failure(let failure):
            print("transaction could not be verified \(failure)")
            return false
        case .success(let success): transaction = success
        }

        return transaction.revocationDate == nil && !transaction.isUpgraded
    }

    @MainActor
    private func updatePurchasedIdentifiers(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            // If the App Store has not revoked the transaction, add it to the list of `purchasedIdentifiers`.
            purchasedIdentifiers.insert(transaction.productID)
        } else {
            // If the App Store has revoked this transaction, remove it from the list of `purchasedIdentifiers`.
            purchasedIdentifiers.remove(transaction.productID)
        }
    }

    private func listenForTransactions() -> Task<Void, Error> {
        Task.detached { [weak self] in
            guard let self = self else { return }

            // Iterate through any transactions which didn't come from a direct call to `purchase()`.
            for await result in Transaction.updates {
                let transaction: Transaction
                let transactionResult = self.checkVerified(result)
                switch transactionResult {
                case .failure(let failure):
                    print("transaction could not be verified \(failure)")
                    continue
                case .success(let success): transaction = success
                }

                await self.updatePurchasedIdentifiers(transaction)

                await transaction.finish()
            }
        }
    }

    private func checkVerified<T>(_ result: VerificationResult<T>) -> Result<T, Errors> {
        switch result {
        // StoreKit has parsed the JWS but failed verification. Don't deliver content to the user.
        case .unverified: return .failure(.failedVerification)
        // If the transaction is verified, unwrap and return it.
        case .verified(let safe): return .success(safe)
        }
    }

    private func withLoading(completion: () async -> Void) async {
        isLoading = true
        await completion()
        isLoading = false
    }

    private static func getInitialProductsMap() -> [String: String] {
        guard let path = Bundle.main.path(forResource: "Products", ofType: "plist"),
              let plist = FileManager.default.contents(atPath: path) else { return [:] }
        let productsMap: [String: String]?
        do {
            productsMap = try PropertyListSerialization.propertyList(from: plist, format: nil) as? [String: String]
        } catch {
            print("failed serializing products property list \(error)")
            return [:]
        }
        return productsMap ?? [:]
    }

}
