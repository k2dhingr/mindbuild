//
//  HealthDashboardView.swift
//  MindfulHealth
//
//  Main dashboard showing health metrics and AI insights
//

import SwiftUI

struct HealthDashboardView: View {
    @EnvironmentObject var healthViewModel: HealthViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your Health")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    
                    Text(formattedDate())
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                // Device capability indicator
                if healthViewModel.hasAppleWatch {
                    HStack {
                        Image(systemName: "applewatch")
                        Text("Apple Watch Connected")
                        Spacer()
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                } else {
                    HStack {
                        Image(systemName: "iphone")
                        Text("iPhone Only Mode")
                        Spacer()
                        Text("Limited Metrics")
                            .font(.system(size: 12))
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                    .padding(.horizontal, 20)
                }
                
                // AI Insight Card (if available)
                if let insight = healthViewModel.currentInsight {
                    AIInsightCard(insight: insight)
                        .padding(.horizontal, 20)
                }
                
                // Metrics Grid
                if !healthViewModel.healthDataManager.latestMetrics.isEmpty {
                    LazyVGrid(
                        columns: [
                            GridItem(.flexible(), spacing: 16),
                            GridItem(.flexible(), spacing: 16)
                        ],
                        spacing: 16
                    ) {
                        ForEach(healthViewModel.healthDataManager.latestMetrics) { metric in
                            HealthCardView(metric: metric)
                        }
                    }
                    .padding(.horizontal, 20)
                } else {
                    // Loading or empty state
                    VStack(spacing: 16) {
                        if healthViewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                            Text("Loading your health data...")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        } else {
                            Image(systemName: "heart.text.square")
                                .font(.system(size: 60))
                                .foregroundColor(.white.opacity(0.3))
                            Text("Pull to refresh your health data")
                                .font(.system(size: 16))
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 60)
                }
                
                // Refresh button
                Button {
                    Task {
                        await healthViewModel.refreshHealthData()
                    }
                } label: {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Refresh Data")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.1))
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .refreshable {
            await healthViewModel.refreshHealthData()
        }
        .task {
            // Auto-refresh on appear
            if healthViewModel.healthDataManager.latestMetrics.isEmpty {
                await healthViewModel.refreshHealthData()
            }
        }
    }
    
    private func formattedDate() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d"
        return formatter.string(from: Date())
    }
}

// MARK: - AI Insight Card
struct AIInsightCard: View {
    let insight: AIInsight
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: priorityIcon)
                    .font(.system(size: 24))
                    .foregroundColor(Color(hex: insight.priority.color))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(insight.title)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text(timeAgo(from: insight.timestamp))
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
            }
            
            Text(insight.message)
                .font(.system(size: 16))
                .foregroundColor(.white.opacity(0.9))
                .lineSpacing(6)
            
            if !insight.actionItems.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach(Array(insight.actionItems.enumerated()), id: \.offset) { index, item in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(index + 1).")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(item)
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color(hex: insight.priority.color).opacity(0.3), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
    }
    
    private var priorityIcon: String {
        switch insight.priority {
        case .high: return "exclamationmark.triangle.fill"
        case .medium: return "lightbulb.fill"
        case .low: return "checkmark.circle.fill"
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        if seconds < 60 { return "Just now" }
        if seconds < 3600 { return "\(Int(seconds / 60))m ago" }
        if seconds < 86400 { return "\(Int(seconds / 3600))h ago" }
        return "\(Int(seconds / 86400))d ago"
    }
}

#Preview {
    HealthDashboardView()
        .environmentObject(HealthViewModel())
        .background(AnimatedGradientView())
}
