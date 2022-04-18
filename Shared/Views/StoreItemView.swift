//
//  StoreItemView.swift
//  StoreKitPlay (iOS)
//
//  Created by Kamaal M Farah on 18/04/2022.
//

import SwiftUI
import SalmonUI

struct StoreItemView: View {
    let item: StoreProduct
    let onPricePress: (_ item: StoreProduct) -> Void

    var body: some View {
        HStack {
            VStack {
                HStack {
                    Text(item.emoji)
                    Text(item.info.displayName)
                        .font(.headline)
                }
                .ktakeWidthEagerly(alignment: .leading)
                Text(item.info.description)
                    .foregroundColor(.secondary)
                    .font(.subheadline)
                    .ktakeWidthEagerly(alignment: .leading)
                    .padding(.top, 1)
            }
            Spacer()
            Button(action: { onPricePress(item) }) {
                KJustStack {
                    if item.isPurchased {
                        Text(Image(systemName: "checkmark"))
                            .foregroundColor(.primary)
                            .bold()
                    } else {
                        Text(item.info.displayPrice)
                            .foregroundColor(.primary)
                            .bold()
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 4)
                .background(Color.accentColor)
                .cornerRadius(16)
            }
            .disabled(item.isPurchased)
        }
    }
}

//struct StoreItemView_Previews: PreviewProvider {
//    static var previews: some View {
//        StoreItemView(item: .init(emoji: "🚗", info: ))
//    }
//}
