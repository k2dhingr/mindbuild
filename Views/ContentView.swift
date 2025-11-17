//
//  ContentView.swift
//  MindfulHealth
//
//  Main container view with navigation
//

import SwiftUI

struct ContentView: View {
    @EnvironmentObject var healthViewModel: HealthViewModel
    @EnvironmentObject var chatViewModel: ChatViewModel
    
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Yutori-style animated background
            AnimatedGradientView()
            
            if healthViewModel.isOnboarding {
                // First-time setup
                OnboardingView()
                    .transition(.opacity)
            } else {
                // Main app interface
                TabView(selection: $selectedTab) {
                    HealthDashboardView()
                        .tabItem {
                            Label("Health", systemImage: "heart.fill")
                        }
                        .tag(0)
                    
                    ChatView()
                        .tabItem {
                            Label("Chat", systemImage: "message.fill")
                        }
                        .tag(1)
                }
                .accentColor(.white)
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(HealthViewModel())
        .environmentObject(ChatViewModel())
}
