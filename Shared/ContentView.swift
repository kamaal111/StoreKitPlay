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
                } else if store.cars.isEmpty {
                    Text("No cars available")
                }
                ForEach(store.cars) { car in
                    VStack {
                        HStack {
                            Text(car.emoji)
                            Text(car.info.displayName)
                                .font(.headline)
                            Spacer()
                            Text(car.info.displayPrice)
                                .bold()
                        }
                        Text(car.info.description)
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                            .ktakeWidthEagerly(alignment: .leading)
                            .padding(.top, 1)
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
