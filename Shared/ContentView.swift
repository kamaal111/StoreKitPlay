//
//  ContentView.swift
//  Shared
//
//  Created by Kamaal M Farah on 17/04/2022.
//

import SwiftUI
import SalmonUI

struct ContentView: View {
    @StateObject private var store = Store()

    var body: some View {
        NavigationView {
            Form {
                if store.isLoading {
                    KActivityIndicator(isAnimating: $store.isLoading, style: .large)
                } else if store.cars.isEmpty && store.fuel.isEmpty {
                    Text("No store items available")
                }
                if !store.cars.isEmpty {
                    Section(header: Text("Cars")) {
                        ForEach(store.cars) { car in
                            StoreItemView(item: car)
                        }
                    }
                }
                if !store.fuel.isEmpty {
                    Section(header: Text("Fuel")) {
                        ForEach(store.fuel) { fuel in
                            StoreItemView(item: fuel)
                        }
                    }
                }
            }
            .navigationTitle(Text("Store Kit Play"))
            #if os(iOS)
            .navigationBarTitleDisplayMode(.large)
            #endif
        }
        #if os(macOS)
        .frame(minWidth: 300, minHeight: 300)
        #endif
        .onAppear(perform: {
            Task {
                await store.requestProducts()
            }
        })
    }
}

struct StoreItemView: View {
    let item: StoreProduct

    var body: some View {
        VStack {
            HStack {
                Text(item.emoji)
                Text(item.info.displayName)
                    .font(.headline)
                Spacer()
                Text(item.info.displayPrice)
                    .bold()
            }
            Text(item.info.description)
                .foregroundColor(.secondary)
                .font(.subheadline)
                .ktakeWidthEagerly(alignment: .leading)
                .padding(.top, 1)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
