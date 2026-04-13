//
//  PacepalWatchApp.swift
//  PacepalWatch Watch App
//
//  Created by Darío Díaz on 13/04/26.
//

import SwiftUI

@main
struct PacepalWatch_Watch_AppApp: App {
    @State private var showSplash = true

    var body: some Scene {
        WindowGroup {
            if showSplash {
                Image("Logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 72, height: 72)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                            showSplash = false
                        }
                    }
            } else {
                ContentView()
            }
        }
    }
}
