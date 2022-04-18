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
    @Published var isLoading = false

    private let productsMap: [String: String]

    init() {
        self.productsMap = Self.getInitialProductsMap()
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

            var cars: [Product] = []

            for product in storeProducts {
                switch product.type {
                case .nonConsumable: cars.append(product)
                default: continue
                }
            }

            print("storeProducts", storeProducts)
            self.cars = cars.map({ product in
                StoreProduct(emoji: productsMap[product.id] ?? "?", info: product)
            })
        })
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

struct StoreProduct: Hashable, Identifiable {
    let emoji: String
    let info: Product

    var id: String { info.id }
}
