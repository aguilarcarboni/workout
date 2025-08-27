import SwiftUI
import HealthKit
import WorkoutKit
import FoundationModels

struct WorkoutSummaryView: View {

    let workout: HKWorkout

    @StateObject private var healthManager = HealthManager.shared
    private let workoutManager = WorkoutManager.shared

    @State private var heartRateData: [Double] = []
    @State private var activityMetrics: [ActivityMetrics] = []
    @State private var matchedActivitySession: ActivitySession?
    @State private var intervalMappings: [IntervalMapping] = []
    @State private var aiEnhancedSummary = ""
    @State private var isGenerating = true
    
    @available(iOS 26.0, *)
    private var model: SystemLanguageModel {
        SystemLanguageModel.default
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isGenerating {
                    ProgressView("Generating workout summary...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else {
                    // AI Summary Display
                    if !aiEnhancedSummary.isEmpty {
                        Text(aiEnhancedSummary)
                            .padding()
                            .background(Color(.systemGray6))
                            .cornerRadius(8)
                    } else {
                        ContentUnavailableView("No AI summary available", systemImage: "sparkles")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Workout Summary")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await generateWorkoutSummary()
        }
    }
    
    @available(iOS 26.0, *)
    private func performAIGeneration(summaryText: String) async {
        guard model.availability == .available else { return }
        
        await MainActor.run {
            isGenerating = true
        }
        
        let instructions = """
        You are a fitness-focused AI assistant. Your role is to help users improve their workouts by analyzing structured workout summaries provided as plain text. You are knowledgeable in training science, biomechanics, cardio conditioning, and strength programming. Your tone is direct yet friendly, like a coach who tells the truth with clarity but supports progress. Focus on:

        * **Specific feedback**: Comment on the intensity, effort, pacing, volume, heart rate trends, and adherence to plan.
        * **Personalization**: Offer relevant suggestions based on the metrics. If heart rate was low during a heavy lift, mention it. If rest intervals are too long, suggest tightening them.
        * **Progress improvement tips**: Comment on how the user can optimize for hypertrophy, strength, cardio, or recovery based on the session.
        * **Highlight discrepancies** between plan vs. execution and advise accordingly.
        * Be brief but insightful. Avoid generic platitudes. If there’s no HR data, mention ways to improve tracking.
        * If unplanned exercises are detected, infer intent and advise on whether they helped or hindered the goal.

        Assume the user is intelligent, experienced in training, and prefers truth over sugarcoating. But don’t be negative—always end with a strong recommendation for improvement or positive reinforcement of effort.

        The input you receive is a full workout summary in plain text. Structure your response as:

        1. **High-level summary of how the session went**
        2. **What went well and why**
        3. **What could be improved (with clear metrics + reasoning)**
        4. **Actionable suggestions (training, form, intensity, recovery, etc.)**
        """
        
        let prompt = Prompt("Here is a workout summary. Analyze the session and provide a performance review based on the data. Include a clear evaluation of the user's effort, any deviations from plan, and how they can optimize future sessions. \(summaryText)")

        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            
            // Log the raw output for debugging
            print("AI RAW OUTPUT:\n\(response.content)")
            
            await MainActor.run {
                aiEnhancedSummary = response.content
            }
        } catch {
            await MainActor.run {
                aiEnhancedSummary = "Error generating AI summary: \(error.localizedDescription)"
            }
        }
    }
    
    private func generateWorkoutSummary() async {
        await MainActor.run { isGenerating = true }
        var summary = ""
        do {
            // Load heart rate data
            heartRateData = try await healthManager.fetchHeartRateData(for: workout)
            
            // Load activity metrics
            activityMetrics = await healthManager.fetchActivityMetrics(for: workout)
            
            // Try to match with existing workout plans
            matchedActivitySession = workoutManager.findMatchingActivitySession(for: workout)

            // Build mapping between actual metrics and planned steps (filtered to this activity type)
            if let session = matchedActivitySession {
                intervalMappings = session.mapMetricsToPlan(for: workout.workoutActivityType, metrics: activityMetrics)
            } else {
                intervalMappings = []
            }
            
            // Header information
            summary += "WORKOUT SUMMARY\n"
            summary += "================\n\n"
            
            summary += "Activity: \(workout.workoutActivityType.displayName)\n"
            summary += "Date: \(formatDate(workout.startDate))\n"
            summary += "Start Time: \(formatTime(workout.startDate))\n"
            summary += "End Time: \(formatTime(workout.endDate))\n\n"
            
            // Statistics
            summary += "OVERVIEW\n"
            summary += "--------\n"
            summary += "Duration: \(formatDuration(workout.duration))\n"
            
            if #available(iOS 18.0, *) {
                if let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    summary += "Calories: \(Int(calories)) kcal\n"
                }
            } else {
                if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    summary += "Calories: \(Int(calories)) kcal\n"
                }
            }
            
            if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                summary += "Distance: \(formatDistance(distance))\n"
            }
            
            if let avgHR = heartRateData.averageHeartRate() {
                summary += "Average Heart Rate: \(Int(avgHR)) bpm\n"
            }

            if heartRateData.isEmpty {
                summary += "No heart rate data available\n"
            } else {
                if let minHR = heartRateData.min(), let maxHR = heartRateData.max() {
                    summary += "Min Heart Rate: \(Int(minHR)) bpm\n"
                    summary += "Max Heart Rate: \(Int(maxHR)) bpm\n"
                }
                summary += "Total Measurements: \(heartRateData.count)\n"
            }
            
            // Combined workout plan + actual metrics
            if !intervalMappings.isEmpty {
                summary += "\nDETAILED WORKOUT (Plan vs Actual)\n"
                summary += "=================================\n"

                for mapping in intervalMappings {
                    // Planned step name or extra work indicator
                    let plannedLabel: String = {
                        if let planned = mapping.plannedStep {
                            return planned.displayName
                        } else {
                            return "Extra / Unplanned"
                        }
                    }()

                    summary += "\n• \(plannedLabel)\n"

                    if let metrics = mapping.metrics {
                        summary += "   Time: \(formatTime(metrics.startDate)) - \(formatTime(metrics.endDate))\n"

                        if let duration = metrics.duration {
                            summary += "   Duration: \(formatDuration(duration))\n"
                        }
                        if let calories = metrics.calories {
                            summary += "   Calories: \(Int(calories)) kcal\n"
                        }
                        if let distance = metrics.distance {
                            summary += "   Distance: \(formatDistance(distance))\n"
                        }
                        if let pace = metrics.pace {
                            summary += "   Pace: \(formatPace(pace))\n"
                        }
                        if let avgHR = metrics.avgHR {
                            summary += "   Avg HR: \(Int(avgHR)) bpm\n"
                        }
                        if let minHR = metrics.minHR, let maxHR = metrics.maxHR {
                            summary += "   HR Range: \(Int(minHR))-\(Int(maxHR)) bpm\n"
                        }
                    } else {
                        summary += "   Status: Planned but not completed.\n"
                    }
                }
            }
            
        } catch {
            summary = "Error loading workout details: \(error.localizedDescription)"
        }
        // Automatically start AI generation after loading data
        if #available(iOS 26.0, *) {
            await performAIGeneration(summaryText: summary)
        }

        await MainActor.run { isGenerating = false }
    }
}
