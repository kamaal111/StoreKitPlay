//
//  Store.swift
//  StoreKitPlay
//
//  Created by Kamaal M Farah on 18/04/2022.
//

import Foundation
import StoreKit

final class Store: ObservableObject {

    @Published private(set) var cars: [Product] = []

    private let productsMap: [String: String]

    init() {
        self.productsMap = Self.getInitialProductsMap()
    }

    @MainActor
    func requestProducts() async {
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

        print("cars", cars)
        self.cars = cars
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
