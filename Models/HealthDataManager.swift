//
//  HealthDataManager.swift
//  MindfulHealth
//
//  Manages HealthKit data access for iPhone and Apple Watch
//

import Foundation
import HealthKit

class HealthDataManager: ObservableObject {
    // The HealthKit store
    private let healthStore = HKHealthStore()
    
    // Published properties for UI updates
    @Published var isAuthorized = false
    @Published var deviceCapability: DeviceCapability = .phoneOnly
    @Published var latestMetrics: [HealthMetric] = []
    @Published var weeklyData: [HealthSummary] = []
    
    // MARK: - Initialization
    init() {
        checkDeviceCapability()
    }
    
    // MARK: - Device Capability Check
    func checkDeviceCapability() {
        #if os(iOS)
        // Check if HealthKit is available
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit not available on this device")
            return
        }
        
        // Check if Apple Watch is paired (indicates more data available)
        // We'll determine this by checking if HRV data exists (Watch-only metric)
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariability)!
        
        let query = HKSampleQuery(
            sampleType: hrvType,
            predicate: HKQuery.predicateForSamples(
                withStart: Date().addingTimeInterval(-7 * 24 * 60 * 60),
                end: Date(),
                options: .strictStartDate
            ),
            limit: 1,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
        ) { [weak self] _, samples, error in
            DispatchQueue.main.async {
                if let samples = samples, !samples.isEmpty {
                    self?.deviceCapability = .phoneAndWatch
                    print("✅ Apple Watch detected - Full metrics available")
                } else {
                    self?.deviceCapability = .phoneOnly
                    print("📱 iPhone only - Limited metrics")
                }
            }
        }
        
        healthStore.execute(query)
        #endif
    }
    
    // MARK: - Request Authorization
    func requestAuthorization() async throws {
        // Define the types we want to read
        let typesToRead: Set<HKObjectType> = [
            // Basic metrics (available on iPhone)
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!,
            
            // Advanced metrics (require Apple Watch)
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariability)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            
            // Workouts
            HKObjectType.workoutType()
        ]
        
        try await healthStore.requestAuthorization(toShare: [], read: typesToRead)
        
        DispatchQueue.main.async {
            self.isAuthorized = true
            print("✅ HealthKit authorization granted")
        }
    }
    
    // MARK: - Fetch Latest Metrics (Last 24 hours)
    func fetchLatestMetrics() async {
        let now = Date()
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        var metrics: [HealthMetric] = []
        
        // Fetch based on device capability
        switch deviceCapability {
        case .phoneOnly:
            // Fetch basic metrics
            if let steps = await fetchSteps(start: oneDayAgo, end: now) {
                metrics.append(steps)
            }
            if let sleep = await fetchSleep(start: oneDayAgo, end: now) {
                metrics.append(sleep)
            }
            
        case .phoneAndWatch:
            // Fetch all available metrics
            if let steps = await fetchSteps(start: oneDayAgo, end: now) {
                metrics.append(steps)
            }
            if let sleep = await fetchSleep(start: oneDayAgo, end: now) {
                metrics.append(sleep)
            }
            if let hr = await fetchAverageHeartRate(start: oneDayAgo, end: now) {
                metrics.append(hr)
            }
            if let hrv = await fetchAverageHRV(start: oneDayAgo, end: now) {
                metrics.append(hrv)
            }
            if let calories = await fetchActiveCalories(start: oneDayAgo, end: now) {
                metrics.append(calories)
            }
            if let restingHR = await fetchRestingHeartRate(start: oneDayAgo, end: now) {
                metrics.append(restingHR)
            }
        }
        
        DispatchQueue.main.async {
            self.latestMetrics = metrics
        }
    }
    
    // MARK: - Fetch Weekly Summary (for trends)
    func fetchWeeklySummary() async {
        let now = Date()
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: now)!
        
        var summaries: [HealthSummary] = []
        
        // Generate summary for each of the last 7 days
        for dayOffset in 0..<7 {
            guard let dayStart = Calendar.current.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart)!
            
            let summary = HealthSummary(
                date: dayStart,
                steps: await fetchSteps(start: dayStart, end: dayEnd)?.value,
                sleepHours: await fetchSleep(start: dayStart, end: dayEnd)?.value,
                avgHeartRate: await fetchAverageHeartRate(start: dayStart, end: dayEnd)?.value,
                hrv: await fetchAverageHRV(start: dayStart, end: dayEnd)?.value,
                activeCalories: await fetchActiveCalories(start: dayStart, end: dayEnd)?.value,
                restingHR: await fetchRestingHeartRate(start: dayStart, end: dayEnd)?.value,
                stepsDeviation: nil, // Will be calculated by FeatureEngineering
                sleepDeviation: nil,
                hrvDeviation: nil
            )
            
            summaries.append(summary)
        }
        
        DispatchQueue.main.async {
            self.weeklyData = summaries.reversed() // Oldest to newest
        }
    }
    
    // MARK: - Individual Metric Fetchers
    
    private func fetchSteps(start: Date, end: Date) async -> HealthMetric? {
        guard let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: stepsType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let steps = sum.doubleValue(for: HKUnit.count())
                let metric = HealthMetric(
                    type: .steps,
                    value: steps,
                    unit: "steps",
                    date: end,
                    isAnomalous: false
                )
                continuation.resume(returning: metric)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchSleep(start: Date, end: Date) async -> HealthMetric? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: sleepType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]
            ) { _, samples, error in
                guard let samples = samples as? [HKCategorySample] else {
                    continuation.resume(returning: nil)
                    return
                }
                
                // Calculate total sleep duration (in bed + asleep stages)
                var totalSleepSeconds: TimeInterval = 0
                for sample in samples {
                    // Only count actual sleep, not "in bed"
                    if sample.value != HKCategoryValueSleepAnalysis.inBed.rawValue {
                        totalSleepSeconds += sample.endDate.timeIntervalSince(sample.startDate)
                    }
                }
                
                let sleepHours = totalSleepSeconds / 3600.0
                
                let metric = HealthMetric(
                    type: .sleepHours,
                    value: sleepHours,
                    unit: "hours",
                    date: end,
                    isAnomalous: false
                )
                continuation.resume(returning: metric)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchAverageHeartRate(start: Date, end: Date) async -> HealthMetric? {
        guard let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                guard let result = result, let avg = result.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let bpm = avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                let metric = HealthMetric(
                    type: .heartRate,
                    value: bpm,
                    unit: "bpm",
                    date: end,
                    isAnomalous: false
                )
                continuation.resume(returning: metric)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchAverageHRV(start: Date, end: Date) async -> HealthMetric? {
        guard let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariability) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: hrvType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                guard let result = result, let avg = result.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let ms = avg.doubleValue(for: HKUnit.secondUnit(with: .milli))
                let metric = HealthMetric(
                    type: .heartRateVariability,
                    value: ms,
                    unit: "ms",
                    date: end,
                    isAnomalous: false
                )
                continuation.resume(returning: metric)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchActiveCalories(start: Date, end: Date) async -> HealthMetric? {
        guard let caloriesType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: caloriesType,
                quantitySamplePredicate: predicate,
                options: .cumulativeSum
            ) { _, result, error in
                guard let result = result, let sum = result.sumQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let calories = sum.doubleValue(for: .kilocalorie())
                let metric = HealthMetric(
                    type: .activeEnergy,
                    value: calories,
                    unit: "kcal",
                    date: end,
                    isAnomalous: false
                )
                continuation.resume(returning: metric)
            }
            
            healthStore.execute(query)
        }
    }
    
    private func fetchRestingHeartRate(start: Date, end: Date) async -> HealthMetric? {
        guard let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else {
            return nil
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
        
        return await withCheckedContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: restingHRType,
                quantitySamplePredicate: predicate,
                options: .discreteAverage
            ) { _, result, error in
                guard let result = result, let avg = result.averageQuantity() else {
                    continuation.resume(returning: nil)
                    return
                }
                
                let bpm = avg.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                let metric = HealthMetric(
                    type: .restingHeartRate,
                    value: bpm,
                    unit: "bpm",
                    date: end,
                    isAnomalous: false
                )
                continuation.resume(returning: metric)
            }
            
            healthStore.execute(query)
        }
    }
}
