//
//  HealthCardView.swift
//  MindfulHealth
//
//  Individual health metric card with gradient styling
//

import SwiftUI

struct HealthCardView: View {
    let metric: HealthMetric
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon with gradient background
            HStack {
                Image(systemName: metric.type.icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
                    .frame(width: 50, height: 50)
                    .background(
                        LinearGradient(
                            colors: [
                                Color(hex: metric.type.color.start),
                                Color(hex: metric.type.color.end)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(12)
                
                Spacer()
                
                if metric.isAnomalous {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.orange)
                }
            }
            
            // Metric name
            Text(metric.type.rawValue)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
            
            // Value
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(formattedValue)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                
                Text(metric.unit)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            
            // Timestamp
            Text(timeAgo(from: metric.date))
                .font(.system(size: 12))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    Color(hex: metric.type.color.start).opacity(0.3),
                                    Color(hex: metric.type.color.end).opacity(0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 4)
    }
    
    private var formattedValue: String {
        switch metric.type {
        case .steps, .activeEnergy, .heartRate, .heartRateVariability, .restingHeartRate:
            return String(format: "%.0f", metric.value)
        case .sleepHours:
            return String(format: "%.1f", metric.value)
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
    VStack {
        HealthCardView(metric: HealthMetric(
            type: .steps,
            value: 8543,
            unit: "steps",
            date: Date(),
            isAnomalous: false
        ))
        
        HealthCardView(metric: HealthMetric(
            type: .sleepHours,
            value: 7.2,
            unit: "hours",
            date: Date().addingTimeInterval(-3600),
            isAnomalous: true
        ))
        
        HealthCardView(metric: HealthMetric(
            type: .heartRateVariability,
            value: 54,
            unit: "ms",
            date: Date(),
            isAnomalous: false
        ))
    }
    .padding()
    .background(AnimatedGradientView())
}
