//
//  OnboardingView.swift
//  MindfulHealth
//
//  First-time setup - requests HealthKit permissions
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var healthViewModel: HealthViewModel
    @State private var currentPage = 0
    
    var body: some View {
        ZStack {
            // Background already handled by ContentView
            
            VStack(spacing: 40) {
                Spacer()
                
                // App logo/name
                VStack(spacing: 16) {
                    Image(systemName: "heart.text.square.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.pink, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                    
                    Text("MindfulHealth")
                        .font(.system(size: 42, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text("AI-Powered Wellness Insights\nPrivate. On-Device. For You.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                        .multilineTextAlignment(.center)
                        .lineSpacing(6)
                }
                
                Spacer()
                
                // Feature highlights
                VStack(alignment: .leading, spacing: 24) {
                    FeatureRow(
                        icon: "brain.head.profile",
                        title: "On-Device AI",
                        description: "All analysis happens on your phone. Your health data never leaves your device."
                    )
                    
                    FeatureRow(
                        icon: "waveform.path.ecg.rectangle",
                        title: "Holistic Insights",
                        description: "Understand the connection between sleep, activity, stress, and recovery."
                    )
                    
                    FeatureRow(
                        icon: "leaf.fill",
                        title: "Actionable Guidance",
                        description: "Get personalized suggestions for meditation, sleep, and wellness."
                    )
                }
                .padding(.horizontal, 32)
                
                Spacer()
                
                // Get Started button
                Button {
                    Task {
                        await healthViewModel.completeOnboarding()
                    }
                } label: {
                    HStack {
                        Text("Get Started")
                            .font(.system(size: 20, weight: .semibold))
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 18, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "667eea"), Color(hex: "764ba2")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "667eea").opacity(0.4), radius: 20, x: 0, y: 10)
                }
                .padding(.horizontal, 32)
                
                // Privacy note
                Text("We'll request access to your Health data.\nYou can choose which data to share.")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 32)
            }
        }
    }
}

// MARK: - Feature Row Component
struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.1))
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
        }
    }
}

// MARK: - Color Extension
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OnboardingView()
        .environmentObject(HealthViewModel())
}
