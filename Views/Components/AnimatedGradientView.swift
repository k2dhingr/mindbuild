//
//  AnimatedGradientView.swift
//  MindfulHealth
//
//  Yutori-inspired animated gradient background
//

import SwiftUI

struct AnimatedGradientView: View {
    @State private var animateGradient = false
    
    // Soft, sophisticated color palette inspired by Yutori
    let colors: [Color] = [
        Color(red: 0.15, green: 0.15, blue: 0.20),  // Deep slate
        Color(red: 0.20, green: 0.25, blue: 0.30),  // Muted blue-grey
        Color(red: 0.18, green: 0.22, blue: 0.26),  // Soft charcoal
        Color(red: 0.16, green: 0.20, blue: 0.25)   // Twilight blue
    ]
    
    var body: some View {
        ZStack {
            // Base gradient
            LinearGradient(
                gradient: Gradient(colors: colors),
                startPoint: animateGradient ? .topLeading : .bottomLeading,
                endPoint: animateGradient ? .bottomTrailing : .topTrailing
            )
            .ignoresSafeArea()
            .onAppear {
                // Smooth, subtle animation
                withAnimation(.easeInOut(duration: 8.0).repeatForever(autoreverses: true)) {
                    animateGradient.toggle()
                }
            }
            
            // Subtle overlay for depth (like Yutori's blur effect)
            Color.black.opacity(0.1)
                .ignoresSafeArea()
        }
    }
}

#Preview {
    AnimatedGradientView()
}
