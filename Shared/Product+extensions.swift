//
//  Product+extensions.swift
//  StoreKitPlay (iOS)
//
//  Created by Kamaal M Farah on 18/04/2022.
//

import StoreKit

extension Product {
    func toStoreProduct(emoji: String) -> StoreProduct {
        .init(emoji: emoji, info: self)
    }
}
