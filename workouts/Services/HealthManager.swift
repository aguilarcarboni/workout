import Foundation
import HealthKit
import WorkoutKit

struct ActivityMetrics {
    let activity: HKWorkoutActivity
    let startDate: Date
    let endDate: Date
    let duration: Double?
    let calories: Double?
    let distance: Double?
    let pace: Double?
    let minHR: Double?
    let maxHR: Double?
    let avgHR: Double?
}

class HealthManager: ObservableObject {
    
    private let healthStore = HKHealthStore()
    static let shared = HealthManager()
    @Published var isAuthorized = false
    @Published var workouts: [HKWorkout] = []
    
    private var typesToRequest: Set<HKSampleType> {
        var types: Set<HKSampleType> = [
            HKWorkoutType.workoutType(),
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
            HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
            HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
            HKQuantityType.quantityType(forIdentifier: .stepCount)!,
            HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!,
            HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!,
            HKQuantityType.quantityType(forIdentifier: .vo2Max)!,
            HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!,
            HKQuantityType.quantityType(forIdentifier: .flightsClimbed)!,
            HKQuantityType.quantityType(forIdentifier: .bodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .leanBodyMass)!,
            HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!,
            HKQuantityType.quantityType(forIdentifier: .walkingAsymmetryPercentage)!,
            HKQuantityType.quantityType(forIdentifier: .dietaryWater)!
        ]
        
        if let exerciseTime = HKQuantityType.quantityType(forIdentifier: .appleExerciseTime) {
            types.insert(exerciseTime)
        }
        
        if let timeInDaylight = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) {
            types.insert(timeInDaylight)
        }
        
        if let mindfulSession = HKCategoryType.categoryType(forIdentifier: .mindfulSession) {
            types.insert(mindfulSession)
        }
        
        if let handwashing = HKCategoryType.categoryType(forIdentifier: .handwashingEvent) {
            types.insert(handwashing)
        }
        
        if let sleep = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) {
            types.insert(sleep)
        }
        
        return types
    }
    
    private let numberFormatter: NumberFormatter = {
        let formatter = NumberFormatter()
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 0
        formatter.numberStyle = .decimal
        return formatter
    }()

    init() {
        requestAuthorization()
        fetchWorkouts()
    }

    func requestAuthorization() {

        healthStore.requestAuthorization(toShare: nil, read: typesToRequest) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
            }
        }
    }

    // Fetch all workouts
    func fetchWorkouts() {
        // Sort this descending pls
        let query = HKSampleQuery(sampleType: HKWorkoutType.workoutType(), predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { [weak self] _, samples, error in
            guard let self = self,
                  let workouts = samples as? [HKWorkout] else { return }
            DispatchQueue.main.async {
                self.workouts = workouts
            }
        }
        healthStore.execute(query)
    }

    // Fetch heart rate data for a specific workout
    func fetchHeartRateData(for workout: HKWorkout) async throws -> [Double] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.dataTypeNotAvailable
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: workout.startDate, end: workout.endDate)
        
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { (query, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(throwing: HealthError.invalidData)
                    return
                }
                
                continuation.resume(returning: samples)
            }
            
            healthStore.execute(query)
        }
        
        return samples.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
    }

    func fetchWorkoutPlanDetails(for workout: HKWorkout) async -> String {
        var prompt = ""
        let activityMetrics = await fetchActivityMetrics(for: workout)
        do {
            if let plan = try await workout.workoutPlan {
                switch plan.workout {
                case .custom(let customWorkout):
                    prompt += "Workout Focus: \(customWorkout.displayName ?? "Undefined")\n"
                    
                    // Warmup
                    if let warmup = customWorkout.warmup {
                        prompt += "Warmup Goal: \(warmup.goal)\n"
                    }
                    
                    // Blocks
                    // The activity metrics are already calculated, just loop through them and add the details to the prompt here, you can assume the metrics are in the same order as the steps. If the metrics run out no problem, it means the workout wasnt done fully.
                    for (index, block) in customWorkout.blocks.enumerated() {
                        prompt += "Workout #\(index + 1):\n"
                        prompt += "Iterations: \(block.iterations)\n"
                        
                        for (stepIndex, step) in block.steps.enumerated() {
                            if let name = step.step.displayName {
                                prompt += "Name: \(name)\n"
                            }
                            prompt += "Goal: \(step.step.goal)\n"
                            
                            if let alert = step.step.alert {
                                prompt += "Alert: \(alert)\n"
                            }

                            // Insert corresponding activity metrics if available
                            /*
                            let flatStepIndex = customWorkout.blocks[0..<index].flatMap { $0.steps }.count + stepIndex
                            if flatStepIndex < activityMetrics.count {
                                let metrics = activityMetrics[flatStepIndex]
                                
                                prompt += "\nMetrics:\n"
                                if let duration = metrics.duration {
                                    prompt += "Duration: \(duration / 60.0) min\n"
                                }
                                if let distance = metrics.distance {
                                    prompt += "Distance: \(distance / 1000.0) km\n"
                                }
                                if let pace = metrics.pace {
                                    prompt += "Pace: \(pace) min/km\n"
                                }
                                if let calories = metrics.calories {
                                    prompt += "Calories: \(calories) kcal\n"
                                }
                                if let avgHR = metrics.avgHR {
                                    prompt += "Avg HR: \(avgHR) bpm\n"
                                }
                                if let minHR = metrics.minHR, let maxHR = metrics.maxHR {
                                    prompt += "HR Range: \(minHR)–\(maxHR) bpm\n"
                                }
                            }
                            */
                        }
                    }
                    
                    // Cooldown
                    if let cooldown = customWorkout.cooldown {
                        prompt += "Cooldown Goal: \(cooldown.goal)\n"
                    }
                    
                case .goal(let goalWorkout):
                    prompt += "Goal Workout Activity: \(goalWorkout.activity)\n"
                    prompt += "Goal: \(goalWorkout.goal)\n"
                    
                case .pacer(let pacerWorkout):
                    prompt += "Pacer Workout Activity: \(pacerWorkout.activity)\n"
                    
                case .swimBikeRun(let triWorkout):
                    prompt += "Swim-Bike-Run Workout Activity: \(triWorkout)\n"
                    
                @unknown default:
                    break
                }
                
            } else {
                print("No workout plan associated with this workout.")
            }
        } catch {
            print("Error fetching workout plan: \(error)")
        }
        return prompt
    }

    // Fetch metrics for each workout activity (interval) in a workout
    func fetchActivityMetrics(for workout: HKWorkout) async -> [ActivityMetrics] {
        guard !workout.workoutActivities.isEmpty else { return [] }
        var results: [ActivityMetrics] = []

        // Ensure activities are processed in reverse chronological order
        let activities = workout.workoutActivities.sorted { $0.startDate > $1.startDate }

        for activity in activities {

            let calories = activity.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
            let distance = activity.statistics(for: HKQuantityType(.distanceWalkingRunning))?.sumQuantity()?.doubleValue(for: .meter())
            
            guard let endDate = activity.endDate else {
                continue // Skip this activity if dates are missing
            }
            let duration = endDate.timeIntervalSince(activity.startDate)
            
            let pace = (distance != nil && duration > 0) ? duration / (distance! / 1000.0) : nil // min/km
        
        
        // Heart rate during this interval
        var minHR: Double? = nil
        var maxHR: Double? = nil
        var avgHR: Double? = nil
        do {
            let hrData = try await fetchHeartRateData(for: activity.startDate, end: endDate)
            if !hrData.isEmpty {
                minHR = hrData.min()
                maxHR = hrData.max()
                avgHR = hrData.reduce(0, +) / Double(hrData.count)
            }
        } catch {
            // Leave HR as nil if not available
        }
            results.append(ActivityMetrics(
                activity: activity,
                startDate: activity.startDate,
                endDate: endDate,
                duration: duration,
                calories: calories,
                distance: distance,
                pace: pace,
                minHR: minHR,
                maxHR: maxHR,
                avgHR: avgHR
            ))
        }
        return results
    }

    // Fetch heart rate data for a specific time window
    func fetchHeartRateData(for start: Date, end: Date) async throws -> [Double] {
        guard let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
            throw HealthError.dataTypeNotAvailable
        }
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let samples = try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<[HKQuantitySample], Error>) in
            let query = HKSampleQuery(
                sampleType: heartRateType,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { (query, samples, error) in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                guard let samples = samples as? [HKQuantitySample] else {
                    continuation.resume(throwing: HealthError.invalidData)
                    return
                }
                continuation.resume(returning: samples)
            }
            healthStore.execute(query)
        }
        return samples.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
    }
    
    // MARK: - Aggregated Metrics
    
    /// Fetches a statistics value for the given type over a date range.
    private func statisticsValue(for type: HKQuantityType, unit: HKUnit, options: HKStatisticsOptions, startDate: Date, endDate: Date = Date()) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: options) { _, statistics, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let quantity: HKQuantity?
                if options.contains(.cumulativeSum) {
                    quantity = statistics?.sumQuantity()
                } else if options.contains(.discreteAverage) {
                    quantity = statistics?.averageQuantity()
                } else {
                    quantity = statistics?.mostRecentQuantity()
                }
                
                continuation.resume(returning: quantity?.doubleValue(for: unit))
            }
            
            self.healthStore.execute(query)
        }
    }
    
    /// Returns the most recent quantity sample for the given type.
    private func mostRecentQuantity(for type: HKQuantityType, unit: HKUnit) async throws -> Double? {
        let predicate = HKQuery.predicateForSamples(withStart: Calendar.current.date(byAdding: .month, value: -3, to: Date()), end: Date())
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                let quantity = (samples as? [HKQuantitySample])?.first?.quantity.doubleValue(for: unit)
                continuation.resume(returning: quantity)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    /// Returns all category samples for a type in the provided range.
    private func categorySamples(for type: HKCategoryType, startDate: Date, endDate: Date = Date()) async throws -> [HKCategorySample] {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)
        
        return try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, samples, error in
                if let error = error {
                    continuation.resume(throwing: error)
                    return
                }
                
                guard let results = samples as? [HKCategorySample] else {
                    continuation.resume(returning: [])
                    return
                }
                
                continuation.resume(returning: results)
            }
            
            self.healthStore.execute(query)
        }
    }
    
    /// Computes a simple sleep score out of 100 based on total sleep in the last night.
    func fetchSleepScore() async -> Int? {
        guard let sleepType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis) else { return nil }
        
        // Consider the last 24 hours for simplicity.
        let startDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        
        do {
            let samples = try await categorySamples(for: sleepType, startDate: startDate)
            let asleepSamples = samples.filter { sample in
                let value = HKCategoryValueSleepAnalysis(rawValue: sample.value) ?? .inBed
                return value == .asleepCore || value == .asleepDeep || value == .asleepREM || value == .asleepUnspecified
            }
            
            let totalSleepSeconds = asleepSamples.reduce(0.0) { partial, sample in
                partial + sample.endDate.timeIntervalSince(sample.startDate)
            }
            
            guard totalSleepSeconds > 0 else { return nil }
            
            let score = min(100, Int((totalSleepSeconds / (8 * 3600)) * 100))
            return score
        } catch {
            return nil
        }
    }
    
    /// Calculates a simple cardio recovery estimate using the most recent workout HR data.
    func fetchCardioRecoveryEstimate() async -> Double? {
        guard let recentWorkout = workouts.sorted(by: { $0.endDate > $1.endDate }).first else { return nil }
        
        do {
            let heartRates = try await fetchHeartRateData(for: recentWorkout)
            guard let peak = heartRates.max(), let final = heartRates.last else { return nil }
            let drop = peak - final
            return drop > 0 ? drop : nil
        } catch {
            return nil
        }
    }
    
    /// Fetches a dictionary of today's key health metrics formatted for display.
    func fetchDailyMetrics() async -> [String: String] {
        let today = Calendar.current.startOfDay(for: Date())
        var metrics: [String: String] = [:]
        
        // Steps
        if let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount) {
            if let steps = (try? await statisticsValue(for: stepsType, unit: .count(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Steps"] = formatNumber(steps, decimals: 0)
            }
        }
        
        // HRV
        if let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) {
            if let hrv = (try? await statisticsValue(for: hrvType, unit: HKUnit.secondUnit(with: .milli), options: .discreteAverage, startDate: today)) ?? nil {
                metrics["HRV"] = "\(formatNumber(hrv, decimals: 1)) ms"
            }
        }
        
        // Resting heart rate
        if let restingHRType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) {
            if let resting = (try? await statisticsValue(for: restingHRType, unit: HKUnit.count().unitDivided(by: .minute()), options: .discreteAverage, startDate: today)) ?? nil {
                metrics["Resting HR"] = "\(formatNumber(resting, decimals: 0)) bpm"
            }
        }
        
        // VO2 Max (most recent)
        if let vo2Type = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
            if let vo2 = (try? await mostRecentQuantity(for: vo2Type, unit: HKUnit.literUnit(with: .milli).unitDivided(by: HKUnit.gramUnit(with: .kilo)).unitDivided(by: HKUnit.minute()))) ?? nil {
                metrics["VO2 Max"] = "\(formatNumber(vo2, decimals: 1)) mL/kg/min"
            }
        }
        
        // Active energy
        if let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) {
            if let energy = (try? await statisticsValue(for: activeEnergyType, unit: .kilocalorie(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Active Energy"] = "\(formatNumber(energy, decimals: 0)) kcal"
            }
        }
        
        // Basal energy
        if let basalEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned) {
            if let basal = (try? await statisticsValue(for: basalEnergyType, unit: .kilocalorie(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Resting Energy"] = "\(formatNumber(basal, decimals: 0)) kcal"
            }
        }
        
        // Distance
        if let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) {
            if let distance = (try? await statisticsValue(for: distanceType, unit: .meter(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Distance"] = formatDistance(distance)
            }
        }
        
        // Flights climbed
        if let flightsType = HKQuantityType.quantityType(forIdentifier: .flightsClimbed) {
            if let flights = (try? await statisticsValue(for: flightsType, unit: .count(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Flights"] = formatNumber(flights, decimals: 0)
            }
        }
        
        // Walking asymmetry
        if let asymmetryType = HKQuantityType.quantityType(forIdentifier: .walkingAsymmetryPercentage) {
            if let asymmetry = (try? await statisticsValue(for: asymmetryType, unit: HKUnit.percent(), options: .discreteAverage, startDate: today)) ?? nil {
                metrics["Walking Asymmetry"] = "\(formatNumber(asymmetry * 100, decimals: 1))%"
            }
        }
        
        // Respiratory rate
        if let respiratoryType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate) {
            if let respiratory = (try? await statisticsValue(for: respiratoryType, unit: HKUnit.count().unitDivided(by: .minute()), options: .discreteAverage, startDate: today)) ?? nil {
                metrics["Respiratory Rate"] = "\(formatNumber(respiratory, decimals: 1)) bpm"
            }
        }
        
        // Time in daylight
        if let daylightType = HKQuantityType.quantityType(forIdentifier: .timeInDaylight) {
            if let daylight = (try? await statisticsValue(for: daylightType, unit: HKUnit.minute(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Time in Daylight"] = "\(formatNumber(daylight, decimals: 0)) min"
            }
        }
        
        // Water intake
        if let waterType = HKQuantityType.quantityType(forIdentifier: .dietaryWater) {
            if let water = (try? await statisticsValue(for: waterType, unit: HKUnit.liter(), options: .cumulativeSum, startDate: today)) ?? nil {
                metrics["Water"] = "\(formatNumber(water, decimals: 2)) L"
            }
        }
        
        // Body metrics (most recent)
        if let weightType = HKQuantityType.quantityType(forIdentifier: .bodyMass) {
            if let weight = (try? await mostRecentQuantity(for: weightType, unit: HKUnit.gramUnit(with: .kilo))) ?? nil {
                metrics["Body Mass"] = "\(formatNumber(weight, decimals: 1)) kg"
            }
        }
        
        if let bodyFatType = HKQuantityType.quantityType(forIdentifier: .bodyFatPercentage) {
            if let bodyFat = (try? await mostRecentQuantity(for: bodyFatType, unit: HKUnit.percent())) ?? nil {
                metrics["Body Fat"] = "\(formatNumber(bodyFat * 100, decimals: 1))%"
            }
        }
        
        if let leanMassType = HKQuantityType.quantityType(forIdentifier: .leanBodyMass) {
            if let leanMass = (try? await mostRecentQuantity(for: leanMassType, unit: HKUnit.gramUnit(with: .kilo))) ?? nil {
                metrics["Lean Mass"] = "\(formatNumber(leanMass, decimals: 1)) kg"
            }
        }
        
        // Mindful minutes
        if let mindfulType = HKCategoryType.categoryType(forIdentifier: .mindfulSession),
           let mindfulSamples = try? await categorySamples(for: mindfulType, startDate: today) {
            let mindfulSeconds = mindfulSamples.reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
            let mindfulMinutes = mindfulSeconds / 60
            metrics["Mindful Minutes"] = "\(formatNumber(mindfulMinutes, decimals: 0)) min"
        }
        
        // Handwashing events (count)
        if let handwashingType = HKCategoryType.categoryType(forIdentifier: .handwashingEvent),
           let samples = try? await categorySamples(for: handwashingType, startDate: today) {
            metrics["Handwashing"] = "\(samples.count) events"
        }
        
        // Sleep score
        if let score = await fetchSleepScore() {
            metrics["Sleep Score"] = "\(score)/100"
        }
        
        // Cardio recovery
        if let recovery = await fetchCardioRecoveryEstimate() {
            metrics["Cardio Recovery"] = "\(formatNumber(recovery, decimals: 0)) bpm drop"
        }
        
        // Workouts summary for today
        let todaysWorkouts = workouts.filter { Calendar.current.isDate($0.startDate, inSameDayAs: Date()) }
        if !todaysWorkouts.isEmpty {
            let totalDuration = todaysWorkouts.reduce(0.0) { $0 + $1.duration }
            metrics["Workouts"] = "\(todaysWorkouts.count) (\(formatDuration(totalDuration)))"
        }
        
        return metrics
    }
    
    private func formatNumber(_ value: Double, decimals: Int) -> String {
        String(format: "%.\(decimals)f", value)
    }

}

enum HealthError: Error {
    case dataTypeNotAvailable
    case invalidData
}
