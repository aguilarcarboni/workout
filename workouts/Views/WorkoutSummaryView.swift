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
    @State private var isLoadingDetails = true
    @State private var summaryText = ""
    @State private var aiEnhancedSummary = ""
    @State private var isGeneratingAI = false
    
    @available(iOS 26.0, *)
    private var model: SystemLanguageModel {
        SystemLanguageModel.default
    }
    
    private var formattedAISummary: AttributedString {
        do {
            // Simple approach: just use the markdown as-is
            return try AttributedString(markdown: aiEnhancedSummary)
        } catch {
            // Fallback to plain text if markdown parsing fails
            return AttributedString(aiEnhancedSummary)
        }
    }
    
    private func cleanupAIMarkdown(_ rawText: String) -> String {
        var cleaned = rawText
        
        // Fix common section headers that AI might generate incorrectly
        cleaned = cleaned
            .replacingOccurrences(of: "Key Performance Highlights and Achievements", with: "### Key Highlights")
            .replacingOccurrences(of: "Areas for Improvement or Optimization", with: "\n### Areas for Improvement")
            .replacingOccurrences(of: "Training Insights and Patterns", with: "\n### Training Insights")
            .replacingOccurrences(of: "Recommendations for Future Workouts", with: "\n### Recommendations")
            .replacingOccurrences(of: "Performance Highlights", with: "### Performance Highlights")
            .replacingOccurrences(of: "Key Highlights", with: "### Key Highlights")
            .replacingOccurrences(of: "Workout Analysis", with: "### Workout Analysis")
        
        // Fix common metric patterns - add bold formatting if missing
        let metricsPatterns = [
            ("Endurance Excellence:", "**Endurance Excellence:**"),
            ("Calorie Burn:", "**Calorie Burn:**"),
            ("Heart Rate Management:", "**Heart Rate Management:**"),
            ("Pace Consistency:", "**Pace Consistency:**"),
            ("Distance:", "**Distance:**"),
            ("Duration:", "**Duration:**"),
            ("Calories:", "**Calories:**"),
            ("Average Heart Rate:", "**Average Heart Rate:**"),
            ("Interval Structure:", "**Interval Structure:**"),
            ("Cool Down Strategies:", "**Cool Down Strategies:**"),
            ("Intensity Peaks:", "**Intensity Peaks:**"),
            ("Heart Rate Zones:", "**Heart Rate Zones:**"),
            ("Introduce Interval Training:", "**Introduce Interval Training:**"),
            ("Incorporate", "**Incorporate")
        ]
        
        for (pattern, replacement) in metricsPatterns {
            cleaned = cleaned.replacingOccurrences(of: pattern, with: replacement)
        }
        
        // Ensure proper spacing after headers
        cleaned = cleaned
            .replacingOccurrences(of: "###", with: "\n###")
            .replacingOccurrences(of: "\n\n###", with: "\n###") // Remove duplicate newlines
        
        // Clean up multiple consecutive newlines
        while cleaned.contains("\n\n\n") {
            cleaned = cleaned.replacingOccurrences(of: "\n\n\n", with: "\n\n")
        }
        
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if isLoadingDetails {
                    ProgressView("Loading workout summary...")
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                } else if isGeneratingAI {
                    VStack(spacing: 16) {
                        ProgressView("Generating AI summary...")
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Analyzing your workout data with Apple Intelligence...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    // AI Summary Display
                    if !aiEnhancedSummary.isEmpty {
                        ScrollView {
                            CustomMarkdownView(text: aiEnhancedSummary)
                                .padding()
                                .background(Color(.systemGray6))
                                .cornerRadius(8)
                        }
                    } else {
                        // Fallback if AI is not available
                        aiUnavailableSection
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Workout Summary")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if #available(iOS 26.0, *), model.availability == .available {
                    Button {
                        Task {
                            await performAIGeneration()
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(Color("AccentColor"))
                    }
                    .disabled(isGeneratingAI)
                }
            }
        }
        .task {
            await loadWorkoutDetails()
        }
    }
    
    private var aiUnavailableSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.orange)
                
                Text("AI Summary Unavailable")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            if #available(iOS 26.0, *) {
                switch model.availability {
                case .available:
                    // This shouldn't happen, but just in case
                    Text("AI is available but summary generation failed")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                case .unavailable(.deviceNotEligible):
                    Text("Apple Intelligence is not supported on this device")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                case .unavailable(.appleIntelligenceNotEnabled):
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Apple Intelligence is not enabled")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Text("Turn on Apple Intelligence in Settings to generate AI summaries")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    
                case .unavailable(.modelNotReady):
                    Text("AI model is downloading... Please try again later")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                case .unavailable(let other):
                    Text("AI unavailable: \(String(describing: other))")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else {
                Text("AI summaries require iOS 26.0 or later")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    

    
    @available(iOS 26.0, *)
    private func performAIGeneration() async {
        guard model.availability == .available else { return }
        
        await MainActor.run {
            isGeneratingAI = true
        }
        
        let instructions = """
        You are a fitness coach and data analyst.

        You must return your answer formatted using valid Markdown syntax ONLY.

        Formatting requirements:
        - Use `###` for section titles (like `### Key Highlights`)
        - Use `**bold**` for metric labels (like `**Calories Burned:** 550 kcal`)
        - Use `-` for bullet points
        - Use proper line breaks between paragraphs
        - DO NOT use emojis, special symbols, or rich text formatting — only valid Markdown syntax

        Example:
        ### Key Highlights

        - **Duration:** 1h 30m  
        - **Calories Burned:** 550 kcal

        ### Areas for Improvement

        - Try to increase time spent in high HR zones

        Analyze the workout data and provide insights in exactly this Markdown format.
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
            
            // Clean up the AI output if it's not proper Markdown
            let cleanedSummary = cleanupAIMarkdown(response.content)
            
            await MainActor.run {
                aiEnhancedSummary = cleanedSummary
                isGeneratingAI = false
            }
        } catch {
            await MainActor.run {
                aiEnhancedSummary = "Error generating AI summary: \(error.localizedDescription)"
                isGeneratingAI = false
            }
        }
    }
    
    private func loadWorkoutDetails() async {
        do {
            // Load heart rate data
            heartRateData = try await healthManager.fetchHeartRateData(for: workout)
            
            // Load activity metrics
            activityMetrics = await healthManager.fetchActivityMetrics(for: workout)
            
            // Try to match with existing workout plans
            matchedActivitySession = workoutManager.findMatchingActivitySession(for: workout)
            
            // Generate summary text for AI processing
            generateSummaryText()
            
        } catch {
            summaryText = "Error loading workout details: \(error.localizedDescription)"
        }
        
        isLoadingDetails = false
        
        // Automatically start AI generation after loading data
        if #available(iOS 26.0, *) {
            await performAIGeneration()
        }
    }
    
    private func generateSummaryText() {
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
        
        // Heart rate data
        summary += "\nHEART RATE DATA\n"
        summary += "---------------\n"
        if heartRateData.isEmpty {
            summary += "No heart rate data available\n"
        } else {
            if let minHR = heartRateData.min(), let maxHR = heartRateData.max() {
                summary += "Min Heart Rate: \(Int(minHR)) bpm\n"
                summary += "Max Heart Rate: \(Int(maxHR)) bpm\n"
            }
            summary += "Total Measurements: \(heartRateData.count)\n"
        }
        
        // Activity metrics
        if !activityMetrics.isEmpty {
            summary += "\nACTIVITY INTERVALS (\(activityMetrics.count))\n"
            summary += "========================\n"
            
            for (index, metrics) in activityMetrics.enumerated() {
                summary += "\nInterval \(index + 1):\n"
                summary += "  Time: \(formatTime(metrics.startDate)) - \(formatTime(metrics.endDate))\n"
                
                if let duration = metrics.duration {
                    summary += "  Duration: \(formatDuration(duration))\n"
                }
                if let calories = metrics.calories {
                    summary += "  Calories: \(Int(calories)) kcal\n"
                }
                if let distance = metrics.distance {
                    summary += "  Distance: \(formatDistance(distance))\n"
                }
                if let pace = metrics.pace {
                    summary += "  Pace: \(formatPace(pace))\n"
                }
                if let avgHR = metrics.avgHR {
                    summary += "  Average HR: \(Int(avgHR)) bpm\n"
                }
                if let minHR = metrics.minHR, let maxHR = metrics.maxHR {
                    summary += "  HR Range: \(Int(minHR))-\(Int(maxHR)) bpm\n"
                }
            }
        }
        
        // Matched workout plan
        if let matchedSession = matchedActivitySession {
            summary += "\nMATCHED WORKOUT PLAN\n"
            summary += "====================\n"
            summary += "Plan: \(matchedSession.displayName)\n"
            
            if !matchedSession.targetMetrics.isEmpty {
                summary += "Target Metrics: \(matchedSession.targetMetrics.map { $0.rawValue }.joined(separator: ", "))\n"
            }
            
            if !matchedSession.targetMuscles.isEmpty {
                summary += "Target Muscles: \(matchedSession.targetMuscles.map { $0.rawValue }.joined(separator: ", "))\n"
            }
            
            summary += "Activity Groups: \(matchedSession.activityGroups.count)\n"
            
            for (groupIndex, group) in matchedSession.activityGroups.enumerated() {
                summary += "\nActivity Group \(groupIndex + 1):\n"
                summary += "  Activity: \(group.activity.displayName)\n"
                summary += "  Location: \(group.location.displayName)\n"
                summary += "  Workouts: \(group.workouts.count)\n"
                
                for (workoutIndex, workout) in group.workouts.enumerated() {
                    summary += "\n  Workout \(workoutIndex + 1):\n"
                    if let workoutType = workout.workoutType {
                        summary += "    Type: \(workoutType.rawValue)\n"
                    }
                    if workout.iterations > 1 {
                        summary += "    Sets: \(workout.iterations)\n"
                    }
                    if !workout.targetMetrics.isEmpty {
                        summary += "    Target Metrics: \(workout.targetMetrics.map { $0.rawValue }.joined(separator: ", "))\n"
                    }
                    if !workout.targetMuscles.isEmpty {
                        summary += "    Target Muscles: \(workout.targetMuscles.map { $0.rawValue }.joined(separator: ", "))\n"
                    }
                    
                    summary += "    Exercises:\n"
                    for (exerciseIndex, exercise) in workout.exercises.enumerated() {
                        summary += "      • \(exercise.displayName) - \(goalDescription(exercise.goal))\n"
                        
                        if exerciseIndex < workout.restPeriods.count {
                            let rest = workout.restPeriods[exerciseIndex]
                            summary += "        Rest: \(rest.displayName) - \(goalDescription(rest.goal))\n"
                        }
                    }
                }
            }
        } else {
            summary += "\nCUSTOM WORKOUT PLAN\n"
            summary += "===================\n"
            summary += "No custom workout plan applied\n"
        }
        
        summaryText = summary
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

struct CustomMarkdownView: View {
    let text: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(parsedContent, id: \.id) { element in
                element.view
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var parsedContent: [MarkdownElement] {
        let lines = text.components(separatedBy: .newlines)
        var elements: [MarkdownElement] = []
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.isEmpty {
                // Skip empty lines - spacing will be handled by VStack
                continue
            } else if trimmed.hasPrefix("### ") {
                // Header
                let headerText = String(trimmed.dropFirst(4))
                elements.append(MarkdownElement(
                    id: UUID(),
                    view: AnyView(
                        Text(headerText)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(Color("AccentColor"))
                            .padding(.top, 8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                ))
            } else {
                // Regular text with bold formatting
                elements.append(MarkdownElement(
                    id: UUID(),
                    view: AnyView(
                        Text(parseInlineMarkdown(trimmed))
                            .font(.body)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    )
                ))
            }
        }
        
        return elements
    }
    
    private func parseInlineMarkdown(_ text: String) -> AttributedString {
        do {
            return try AttributedString(markdown: text)
        } catch {
            return AttributedString(text)
        }
    }
}

struct MarkdownElement {
    let id: UUID
    let view: AnyView
}

#Preview {
    NavigationView {
        WorkoutSummaryView(workout: HKWorkout(
            activityType: .running,
            start: Date().addingTimeInterval(-3600),
            end: Date()
        ))
    }
} 