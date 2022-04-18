//
//  StoreProduct.swift
//  StoreKitPlay (iOS)
//
//  Created by Kamaal M Farah on 18/04/2022.
//

import StoreKit

struct StoreProduct: Hashable, Identifiable {
    let emoji: String
    let info: Product

    var id: String { info.id }
}
