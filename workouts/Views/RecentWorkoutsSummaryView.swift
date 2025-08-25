import SwiftUI
import HealthKit
import WorkoutKit
import FoundationModels

struct RecentWorkoutsSummaryView: View {
    let workouts: [HKWorkout]
    @StateObject private var healthManager = HealthManager.shared
    @State private var heartRateData: [Double] = []
    @State private var intervalMappingsArray: [[IntervalMapping]] = []
    @State private var isGenerating = true
    @State private var aiEnhancedSummary = ""

    private func loadDetails() async {
        // Start loading – show progress indicator
        await MainActor.run { isGenerating = true }

        // Fetch heart-rate samples for every workout
        var allHR: [Double] = []
        var allMappings: [[IntervalMapping]] = []

        for workout in workouts {
            do {
                // Heart rate
                let hr = try await healthManager.fetchHeartRateData(for: workout)
                allHR.append(contentsOf: hr)

                // Activity metrics + plan mapping
                let metrics = await healthManager.fetchActivityMetrics(for: workout)
                let matched = WorkoutManager.shared.findMatchingActivitySession(for: workout)
                if let session = matched {
                    let mappings = session.mapMetricsToPlan(for: workout.workoutActivityType, metrics: metrics)
                    allMappings.append(mappings)
                } else {
                    allMappings.append([])
                }
            } catch {
                print("Heart rate fetch error: \(error)")
                allMappings.append([])
            }
        }

        // Publish heart-rate data on the main actor so the view can react
        await MainActor.run {
            heartRateData = allHR
            intervalMappingsArray = allMappings
        }

        // Generate the textual summary now that heart-rate data is available
        let summaryText: String = await MainActor.run { generateSummaryText() }

        // Ask the LLM for an AI-enhanced summary (iOS 26+ only)
        if #available(iOS 26.0, *) {
            await performAIGeneration(summaryText: summaryText)
        }

        // Finished – hide progress indicator
        await MainActor.run { isGenerating = false }
    }
    
    // MARK: - Summary Generation
    private func generateSummaryText() -> String {
        var summary = ""
        summary += "SUMMARY FOR LAST \(workouts.count) WORKOUTS\n"
        summary += "============================\n\n"
        
        // Aggregate totals
        let totalDuration = workouts.reduce(0) { $0 + $1.duration }
        var totalCalories: Double = 0
        var totalDistance: Double = 0
        
        for workout in workouts {
            // Calories
            if #available(iOS 18.0, *) {
                if let cal = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    totalCalories += cal
                }
            } else {
                if let cal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    totalCalories += cal
                }
            }
            // Distance
            if let dist = workout.totalDistance?.doubleValue(for: .meter()) {
                totalDistance += dist
            }
        }
        
        summary += "Total Duration: \(formatDuration(totalDuration))\n"
        summary += "Total Calories: \(Int(totalCalories)) kcal\n"
        summary += "Total Distance: \(formatDistance(totalDistance))\n"
        
        if let avgHR = heartRateData.averageHeartRate() {
            summary += "Average Heart Rate: \(Int(avgHR)) bpm\n"
        }
        
        // List individual workouts
        summary += "\nINDIVIDUAL WORKOUTS\n"
        summary += "-------------------\n"
        for (index, workout) in workouts.enumerated() {
            summary += "Workout \(index + 1): \(formatDate(workout.startDate)) - \(workout.workoutActivityType.displayName)\n"
            summary += "  Duration: \(formatDuration(workout.duration))\n"
            if #available(iOS 18.0, *) {
                if let cal = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                    summary += "  Calories: \(Int(cal)) kcal\n"
                }
            } else {
                if let cal = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    summary += "  Calories: \(Int(cal)) kcal\n"
                }
            }
            if let dist = workout.totalDistance?.doubleValue(for: .meter()) {
                summary += "  Distance: \(formatDistance(dist))\n"
            }

            // Include plan vs actual details
            let mappings = (index < intervalMappingsArray.count) ? intervalMappingsArray[index] : []
            if !mappings.isEmpty {
                summary += "  Intervals: \(mappings.count)\n"
                for mapping in mappings {
                    let plannedName = mapping.plannedStep?.displayName ?? "Extra / Unplanned"
                    summary += "    • \(plannedName) - "
                    if let duration = mapping.metrics?.duration {
                        summary += "\(formatDuration(duration))"
                    } else {
                        summary += "not completed"
                    }
                    summary += "\n"
                }
            }
            summary += "\n"
        }
        return summary
    }

    @available(iOS 26.0, *)
    private var model: SystemLanguageModel {
        SystemLanguageModel.default
    }
    
    // MARK: - AI Generation
    @available(iOS 26.0, *)
    private func performAIGeneration(summaryText: String) async {
        guard model.availability == .available else { return }
        
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

        Use only **bold** tags, no header or subheaders.Add emojis when appropriate.
        """
        
        let prompt = """
        You are given the last \(workouts.count) structured workout summaries in plain text format. Analyze the user's training over time.

        Here is the summary:

        \(summaryText)
        """
        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            await MainActor.run {
                aiEnhancedSummary = response.content
            }
        } catch {
            await MainActor.run {
                aiEnhancedSummary = "Error generating AI summary: \(error.localizedDescription)"
            }
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isGenerating {
                    VStack(spacing: 16) {
                        ProgressView("Generating AI summary...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding()
                } else {
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
        .navigationTitle("Last \(workouts.count) Workouts")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadDetails()
        }
    }

}
