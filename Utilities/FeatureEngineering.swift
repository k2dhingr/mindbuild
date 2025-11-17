//
//  FeatureEngineering.swift
//  MindfulHealth
//
//  Analyzes health data to detect patterns and anomalies
//  Prepares context for the on-device LLM
//

import Foundation

class FeatureEngineering {
    
    // MARK: - Calculate Baselines (7-day averages)
    static func calculateBaselines(from weeklyData: [HealthSummary]) -> HealthBaseline {
        var totalSteps: Double = 0
        var totalSleep: Double = 0
        var totalHR: Double = 0
        var totalHRV: Double = 0
        var totalCalories: Double = 0
        var totalRestingHR: Double = 0
        
        var stepsCount = 0
        var sleepCount = 0
        var hrCount = 0
        var hrvCount = 0
        var caloriesCount = 0
        var restingHRCount = 0
        
        for summary in weeklyData {
            if let steps = summary.steps {
                totalSteps += steps
                stepsCount += 1
            }
            if let sleep = summary.sleepHours {
                totalSleep += sleep
                sleepCount += 1
            }
            if let hr = summary.avgHeartRate {
                totalHR += hr
                hrCount += 1
            }
            if let hrv = summary.hrv {
                totalHRV += hrv
                hrvCount += 1
            }
            if let calories = summary.activeCalories {
                totalCalories += calories
                caloriesCount += 1
            }
            if let restingHR = summary.restingHR {
                totalRestingHR += restingHR
                restingHRCount += 1
            }
        }
        
        return HealthBaseline(
            avgSteps: stepsCount > 0 ? totalSteps / Double(stepsCount) : nil,
            avgSleep: sleepCount > 0 ? totalSleep / Double(sleepCount) : nil,
            avgHeartRate: hrCount > 0 ? totalHR / Double(hrCount) : nil,
            avgHRV: hrvCount > 0 ? totalHRV / Double(hrvCount) : nil,
            avgCalories: caloriesCount > 0 ? totalCalories / Double(caloriesCount) : nil,
            avgRestingHR: restingHRCount > 0 ? totalRestingHR / Double(restingHRCount) : nil
        )
    }
    
    // MARK: - Detect Anomalies (Z-score based)
    static func detectAnomalies(
        current: HealthSummary,
        baseline: HealthBaseline,
        weeklyData: [HealthSummary]
    ) -> [AnomalyDetection] {
        var anomalies: [AnomalyDetection] = []
        
        // Steps anomaly
        if let currentSteps = current.steps,
           let avgSteps = baseline.avgSteps {
            let stdDev = calculateStdDev(values: weeklyData.compactMap { $0.steps })
            let zScore = (currentSteps - avgSteps) / stdDev
            
            if abs(zScore) > 1.5 { // Significant deviation
                anomalies.append(AnomalyDetection(
                    metric: .steps,
                    currentValue: currentSteps,
                    baselineValue: avgSteps,
                    deviation: zScore,
                    severity: abs(zScore) > 2.0 ? .high : .medium
                ))
            }
        }
        
        // Sleep anomaly
        if let currentSleep = current.sleepHours,
           let avgSleep = baseline.avgSleep {
            let stdDev = calculateStdDev(values: weeklyData.compactMap { $0.sleepHours })
            let zScore = (currentSleep - avgSleep) / stdDev
            
            if abs(zScore) > 1.5 {
                anomalies.append(AnomalyDetection(
                    metric: .sleepHours,
                    currentValue: currentSleep,
                    baselineValue: avgSleep,
                    deviation: zScore,
                    severity: abs(zScore) > 2.0 ? .high : .medium
                ))
            }
        }
        
        // HRV anomaly (important stress indicator)
        if let currentHRV = current.hrv,
           let avgHRV = baseline.avgHRV {
            let stdDev = calculateStdDev(values: weeklyData.compactMap { $0.hrv })
            let zScore = (currentHRV - avgHRV) / stdDev
            
            // Low HRV is concerning (indicates stress/poor recovery)
            if zScore < -1.5 {
                anomalies.append(AnomalyDetection(
                    metric: .heartRateVariability,
                    currentValue: currentHRV,
                    baselineValue: avgHRV,
                    deviation: zScore,
                    severity: zScore < -2.0 ? .high : .medium
                ))
            }
        }
        
        // Resting HR anomaly (elevated = potential illness/stress)
        if let currentRestingHR = current.restingHR,
           let avgRestingHR = baseline.avgRestingHR {
            let stdDev = calculateStdDev(values: weeklyData.compactMap { $0.restingHR })
            let zScore = (currentRestingHR - avgRestingHR) / stdDev
            
            // Elevated resting HR is concerning
            if zScore > 1.5 {
                anomalies.append(AnomalyDetection(
                    metric: .restingHeartRate,
                    currentValue: currentRestingHR,
                    baselineValue: avgRestingHR,
                    deviation: zScore,
                    severity: zScore > 2.0 ? .high : .medium
                ))
            }
        }
        
        return anomalies
    }
    
    // MARK: - Generate LLM Context (formatted for Gemma input)
    static func generateLLMContext(
        baseline: HealthBaseline,
        current: HealthSummary,
        anomalies: [AnomalyDetection],
        weeklyData: [HealthSummary]
    ) -> String {
        var context = "### Health Data Summary\n\n"
        
        // Current metrics
        context += "**Today's Metrics:**\n"
        if let steps = current.steps {
            context += "- Steps: \(Int(steps))\n"
        }
        if let sleep = current.sleepHours {
            context += "- Sleep: \(String(format: "%.1f", sleep)) hours\n"
        }
        if let hr = current.avgHeartRate {
            context += "- Avg Heart Rate: \(Int(hr)) bpm\n"
        }
        if let hrv = current.hrv {
            context += "- HRV: \(Int(hrv)) ms\n"
        }
        if let restingHR = current.restingHR {
            context += "- Resting Heart Rate: \(Int(restingHR)) bpm\n"
        }
        if let calories = current.activeCalories {
            context += "- Active Calories: \(Int(calories)) kcal\n"
        }
        
        context += "\n**7-Day Baselines:**\n"
        if let avgSteps = baseline.avgSteps {
            context += "- Avg Steps: \(Int(avgSteps))\n"
        }
        if let avgSleep = baseline.avgSleep {
            context += "- Avg Sleep: \(String(format: "%.1f", avgSleep)) hours\n"
        }
        if let avgHR = baseline.avgHeartRate {
            context += "- Avg Heart Rate: \(Int(avgHR)) bpm\n"
        }
        if let avgHRV = baseline.avgHRV {
            context += "- Avg HRV: \(Int(avgHRV)) ms\n"
        }
        
        // Anomalies
        if !anomalies.isEmpty {
            context += "\n**Detected Patterns:**\n"
            for anomaly in anomalies {
                let direction = anomaly.deviation > 0 ? "increased" : "decreased"
                let percentage = abs((anomaly.currentValue - anomaly.baselineValue) / anomaly.baselineValue * 100)
                context += "- \(anomaly.metric.rawValue) \(direction) by \(Int(percentage))% from baseline\n"
            }
        }
        
        // Week trend
        context += "\n**Weekly Trend:**\n"
        if let recentSleep = weeklyData.suffix(3).compactMap({ $0.sleepHours }).average(),
           let earlierSleep = weeklyData.prefix(3).compactMap({ $0.sleepHours }).average() {
            let sleepTrend = recentSleep - earlierSleep
            context += "- Sleep: \(sleepTrend > 0 ? "improving" : "declining") (\(String(format: "%.1f", abs(sleepTrend))) hours)\n"
        }
        
        return context
    }
    
    // MARK: - Helper: Calculate Standard Deviation
    private static func calculateStdDev(values: [Double]) -> Double {
        guard values.count > 1 else { return 1.0 }
        
        let mean = values.reduce(0, +) / Double(values.count)
        let variance = values.map { pow($0 - mean, 2) }.reduce(0, +) / Double(values.count)
        return sqrt(variance)
    }
}

// MARK: - Supporting Structures

struct HealthBaseline {
    let avgSteps: Double?
    let avgSleep: Double?
    let avgHeartRate: Double?
    let avgHRV: Double?
    let avgCalories: Double?
    let avgRestingHR: Double?
}

struct AnomalyDetection {
    let metric: HealthMetric.MetricType
    let currentValue: Double
    let baselineValue: Double
    let deviation: Double // Z-score
    let severity: Severity
    
    enum Severity {
        case high    // |Z-score| > 2.0
        case medium  // |Z-score| > 1.5
        case low     // |Z-score| > 1.0
    }
}

// MARK: - Array Extension for Average
extension Array where Element == Double {
    func average() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
