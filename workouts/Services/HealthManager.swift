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

    private let typesToRequest: Set<HKSampleType> = [
        HKWorkoutType.workoutType(),
        HKQuantityType.quantityType(forIdentifier: .heartRate)!,
        HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!,
        HKQuantityType.quantityType(forIdentifier: .distanceCycling)!,
        HKQuantityType.quantityType(forIdentifier: .distanceSwimming)!,
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
    ]

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

}

enum HealthError: Error {
    case dataTypeNotAvailable
    case invalidData
}
