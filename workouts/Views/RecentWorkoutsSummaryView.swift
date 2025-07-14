import SwiftUI
import HealthKit
import WorkoutKit
import FoundationModels

struct RecentWorkoutsSummaryView: View {
    let workouts: [HKWorkout]
    @StateObject private var healthManager = HealthManager.shared
    @State private var heartRateData: [Double] = []
    @State private var isGenerating = true
    @State private var aiEnhancedSummary = ""
    
    @available(iOS 26.0, *)
    private var model: SystemLanguageModel {
        SystemLanguageModel.default
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
    
    // MARK: - Data Loading
    private func loadDetails() async {
        // Start loading – show progress indicator
        await MainActor.run { isGenerating = true }

        // Fetch heart-rate samples for every workout
        var allHR: [Double] = []
        for workout in workouts {
            do {
                let hr = try await healthManager.fetchHeartRateData(for: workout)
                allHR.append(contentsOf: hr)
            } catch {
                // Ignore error for individual workout, continue with others
                print("Heart rate fetch error: \(error)")
            }
        }

        // Publish heart-rate data on the main actor so the view can react
        await MainActor.run {
            heartRateData = allHR
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
        
        if let avgHR = calculateAverageHeartRate() {
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
            summary += "\n"
        }
        return summary
    }
    
    // MARK: - AI Generation
    @available(iOS 26.0, *)
    private func performAIGeneration(summaryText: String) async {
        guard model.availability == .available else { return }
        
        let instructions = """
        You are a fitness coach and data analyst.

        Produce a Markdown formatted summary for the last \(workouts.count) workouts using clear section headers (###) and bullet points where appropriate. Follow the same formatting guidelines as previous summaries.
        """
        
        let prompt = """
        Analyze the following workout data and provide insights:
        
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
    
    // MARK: - Helper Functions
    private func calculateAverageHeartRate() -> Double? {
        guard !heartRateData.isEmpty else { return nil }
        return heartRateData.reduce(0, +) / Double(heartRateData.count)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = Int(duration) % 3600 / 60
        let seconds = Int(duration) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.2f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
}
