// ArbitlyApp.swift
import SwiftUI

@main
struct ArbitlyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(ArbitrageViewModel())
        }
    }
}