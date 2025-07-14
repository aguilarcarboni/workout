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
            await loadWorkoutDetails()
        }
    }
    
    @available(iOS 26.0, *)
    private func performAIGeneration(summaryText: String) async {
        guard model.availability == .available else { return }
        
        await MainActor.run {
            isGenerating = true
        }
        
        let instructions = """
        You are a fitness coach and data analyst.
        """
        
        let prompt = """
        Please analyze this workout data and provide an insightful summary:
        
        \(summaryText)
        """
        
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
    
    private func loadWorkoutDetails() async {
        await MainActor.run { isGenerating = true }
        var summaryText = ""
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
            
            // Generate summary text for AI processing
            summaryText = generateSummaryText()
            
        } catch {
            summaryText = "Error loading workout details: \(error.localizedDescription)"
        }
        // Automatically start AI generation after loading data
        if #available(iOS 26.0, *) {
            await performAIGeneration(summaryText: summaryText)
        }

        await MainActor.run { isGenerating = false }
    }
    
    private func generateSummaryText() -> String {
        var summary = ""
        
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
        
        if let avgHR = calculateAverageHeartRate() {
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

        print("Summary: \(summary)")
        
        return summary
    }
    
    private func calculateAverageHeartRate() -> Double? {
        guard !heartRateData.isEmpty else { return nil }
        return heartRateData.reduce(0, +) / Double(heartRateData.count)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        return formatter.string(from: date)
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
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
    
    private func formatPace(_ pace: Double) -> String {
        let minutes = Int(pace) / 60
        let seconds = Int(pace) % 60
        return String(format: "%d:%02d /km", minutes, seconds)
    }
    
    private func goalDescription(_ goal: WorkoutGoal) -> String {
        switch goal {
        case .time(let duration, _):
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            if minutes > 0 {
                return String(format: "%d:%02d", minutes, seconds)
            } else {
                return "\(seconds)s"
            }
        case .distance(let distance, let unit):
            return String(format: "%.1f %@", distance, unit.symbol)
        case .open:
            return "Open"
        @unknown default:
            return "Unknown"
        }
    }
}
