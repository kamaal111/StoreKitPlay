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
                            StoreItemView(item: car, onPricePress: { item in
                                Task { await store.purchase(item) }
                            })
                        }
                    }
                }
                if !store.fuel.isEmpty {
                    Section(header: Text("Fuel")) {
                        ForEach(store.fuel) { fuel in
                            StoreItemView(item: fuel, onPricePress: { item in
                                Task { await store.purchase(item) }
                            })
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

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
