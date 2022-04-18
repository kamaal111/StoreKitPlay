//
//  ContentView.swift
//  Shared
//
//  Created by Kamaal M Farah on 17/04/2022.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var store = Store()

    var body: some View {
        NavigationView {
            Form {
                if store.cars.isEmpty {
                    Text("No cars available")
                }
                ForEach(store.cars, id: \.id) { car in
                    Text(car.displayName)
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
