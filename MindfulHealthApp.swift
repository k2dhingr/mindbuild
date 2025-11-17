//
//  MindfulHealthApp.swift
//  MindfulHealth
//
//  Created for ARM AI Developer Challenge 2025
//  Built with ExecuTorch + Gemma 3n-E2B for on-device AI
//

import SwiftUI

@main
struct MindfulHealthApp: App {
    // State management for app-wide data
    @StateObject private var healthViewModel = HealthViewModel()
    @StateObject private var chatViewModel = ChatViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthViewModel)
                .environmentObject(chatViewModel)
                .preferredColorScheme(.dark) // Yutori-style dark theme
        }
    }
}
