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
    var isPurchased: Bool

    enum ItemTypes {
        case car
        case fuel
    }

    var id: String { info.id }

    var itemType: ItemTypes? {
        switch info.type {
        case .consumable: return .fuel
        case .nonConsumable: return .car
        default: return nil
        }
    }
}
