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

    private let productsMap: [String: String]

    init() {
        self.productsMap = Self.getInitialProductsMap()
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
                let customProduct = product.toStoreProduct(emoji: productsMap[product.id] ?? "?")
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

    @MainActor
    func updatePurchasedIdentifiers(_ transaction: Transaction) async {
        if transaction.revocationDate == nil {
            // If the App Store has not revoked the transaction, add it to the list of `purchasedIdentifiers`.
            purchasedIdentifiers.insert(transaction.productID)
        } else {
            // If the App Store has revoked this transaction, remove it from the list of `purchasedIdentifiers`.
            purchasedIdentifiers.remove(transaction.productID)
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
