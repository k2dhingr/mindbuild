//
//  HealthViewModel.swift
//  MindfulHealth
//
//  Main view model coordinating health data and AI insights
//

import Foundation
import SwiftUI

@MainActor
class HealthViewModel: ObservableObject {
    // Data managers
    let healthDataManager = HealthDataManager()
    let llmManager = LLMManager()
    
    // Published state
    @Published var isOnboarding = true
    @Published var isLoading = false
    @Published var currentInsight: AIInsight?
    @Published var baseline: HealthBaseline?
    @Published var anomalies: [AnomalyDetection] = []
    
    // Computed properties
    var hasAppleWatch: Bool {
        healthDataManager.deviceCapability == .phoneAndWatch
    }
    
    var availableMetrics: [HealthMetric.MetricType] {
        healthDataManager.deviceCapability.availableMetrics
    }
    
    // MARK: - Onboarding
    func completeOnboarding() async {
        do {
            try await healthDataManager.requestAuthorization()
            isOnboarding = false
            
            // Initial data fetch
            await refreshHealthData()
        } catch {
            print("❌ Authorization failed: \(error)")
        }
    }
    
    // MARK: - Refresh Health Data
    func refreshHealthData() async {
        isLoading = true
        
        // Fetch latest metrics
        await healthDataManager.fetchLatestMetrics()
        
        // Fetch weekly summary
        await healthDataManager.fetchWeeklySummary()
        
        // Calculate baseline
        baseline = FeatureEngineering.calculateBaselines(
            from: healthDataManager.weeklyData
        )
        
        // Detect anomalies
        if let latestSummary = healthDataManager.weeklyData.last,
           let baseline = baseline {
            anomalies = FeatureEngineering.detectAnomalies(
                current: latestSummary,
                baseline: baseline,
                weeklyData: healthDataManager.weeklyData
            )
        }
        
        // Generate AI insight
        await generateInsight()
        
        isLoading = false
    }
    
    // MARK: - Generate AI Insight
    private func generateInsight() async {
        guard let latestSummary = healthDataManager.weeklyData.last,
              let baseline = baseline else {
            return
        }
        
        // Prepare context for LLM
        let context = FeatureEngineering.generateLLMContext(
            baseline: baseline,
            current: latestSummary,
            anomalies: anomalies,
            weeklyData: healthDataManager.weeklyData
        )
        
        // Generate insight
        let response = await llmManager.generateHealthInsight(healthContext: context)
        
        // Determine priority based on anomalies
        let priority: AIInsight.Priority = {
            if anomalies.contains(where: { $0.severity == .high }) {
                return .high
            } else if !anomalies.isEmpty {
                return .medium
            } else {
                return .low
            }
        }()
        
        // Extract action items from response (simple parsing)
        let actionItems = extractActionItems(from: response)
        
        currentInsight = AIInsight(
            title: priority == .high ? "Attention Needed" : priority == .medium ? "Insight" : "Keep It Up",
            message: response,
            priority: priority,
            actionItems: actionItems,
            timestamp: Date()
        )
    }
    
    // MARK: - Helper: Extract Action Items
    private func extractActionItems(from response: String) -> [String] {
        // Simple extraction - look for numbered lists or sentences with "try", "consider", "aim for"
        var items: [String] = []
        
        let keywords = ["try this:", "consider", "i'd recommend:", "aim for"]
        let sentences = response.components(separatedBy: ". ")
        
        for sentence in sentences {
            let lowerSentence = sentence.lowercased()
            if keywords.contains(where: { lowerSentence.contains($0) }) {
                items.append(sentence.trimmingCharacters(in: .whitespacesAndNewlines))
            }
        }
        
        return items.isEmpty ? [response] : items
    }
}
