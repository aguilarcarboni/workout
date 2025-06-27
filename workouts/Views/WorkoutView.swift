import SwiftUI
import HealthKit
import WorkoutKit
import Combine

struct WorkoutView: View {
    let workout: HKWorkout
    @StateObject private var healthManager = HealthManager.shared
    private let workoutManager = WorkoutManager.shared
    @State private var heartRateData: [Double] = []
    @State private var activityMetrics: [ActivityMetrics] = []
    @State private var matchedActivitySession: ActivitySession?
    @State private var isLoadingDetails = true
    @State private var showingFullPlan = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                headerSection
                statisticsSection
                heartRateSection
                if !activityMetrics.isEmpty {
                    activityMetricsSection
                }
                if let matchedSession = matchedActivitySession {
                    matchedWorkoutPlanSection(matchedSession)
                } else {
                    noCustomWorkoutSection
                }
            }
            .padding()
        }
        .navigationTitle("Workout Details")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadWorkoutDetails()
        }
    }
    
    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 12) {
                         HStack {
                 Image(systemName: workout.workoutActivityType.icon)
                     .font(.title2)
                     .foregroundColor(Color("AccentColor"))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutActivityType.displayName)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(workout.startDate, style: .date)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack {
                Text(workout.startDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text("-")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(workout.endDate, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Overview")
                .font(.headline)
                .fontWeight(.semibold)
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                StatCard(
                    title: "Duration",
                    value: formatDuration(workout.duration),
                    icon: "clock",
                    color: .blue
                )
                
                if #available(iOS 18.0, *) {
                    if let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                        StatCard(
                            title: "Calories",
                            value: "\(Int(calories)) kcal",
                            icon: "flame",
                            color: .orange
                        )
                    }
                } else {
                    if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                        StatCard(
                            title: "Calories",
                            value: "\(Int(calories)) kcal",
                            icon: "flame",
                            color: .orange
                        )
                    }
                }
                
                if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                    StatCard(
                        title: "Distance",
                        value: formatDistance(distance),
                        icon: "location",
                        color: .green
                    )
                }
                
                if let avgHR = calculateAverageHeartRate() {
                    StatCard(
                        title: "Avg Heart Rate",
                        value: "\(Int(avgHR)) bpm",
                        icon: "heart",
                        color: .red
                    )
                }
            }
        }
    }
    
    private var heartRateSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate")
                .font(.headline)
                .fontWeight(.semibold)
            
            if isLoadingDetails {
                ProgressView("Loading heart rate data...")
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else if heartRateData.isEmpty {
                Text("No heart rate data available")
                    .foregroundColor(.secondary)
                    .font(.caption)
                    .padding()
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        if let minHR = heartRateData.min(),
                           let maxHR = heartRateData.max() {
                            StatCard(
                                title: "Min HR",
                                value: "\(Int(minHR)) bpm",
                                icon: "arrow.down",
                                color: .blue
                            )
                            
                            StatCard(
                                title: "Max HR",
                                value: "\(Int(maxHR)) bpm",
                                icon: "arrow.up",
                                color: .red
                            )
                        }
                    }
                    
                    Text("Recorded \(heartRateData.count) heart rate measurements")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
        }
    }
    
    private var activityMetricsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Activity Intervals (\(activityMetrics.count))")
                .font(.headline)
                .fontWeight(.semibold)
            
            ForEach(Array(activityMetrics.enumerated()), id: \.offset) { index, metrics in
                ActivityMetricsCard(metrics: metrics, index: index + 1)
            }
        }
    }
    
    private func matchedWorkoutPlanSection(_ session: ActivitySession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
                    .font(.caption)
                
                Text("Matched Workout Plan")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button(showingFullPlan ? "Show Less" : "Show More") {
                    showingFullPlan.toggle()
                }
                .font(.caption)
                .foregroundColor(Color("AccentColor"))
            }
            
            // Session overview
            VStack(alignment: .leading, spacing: 8) {
                Text(session.displayName)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AccentColor"))
                
                HStack {
                    if !session.targetMetrics.isEmpty {
                        Label(session.targetMetrics.map { $0.rawValue }.joined(separator: ", "), systemImage: "target")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                    
                    Spacer()
                    
                    Text("\(session.activityGroups.count) activity group\(session.activityGroups.count == 1 ? "" : "s")")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                if !session.targetMuscles.isEmpty {
                    Label(session.targetMuscles.map { $0.rawValue }.joined(separator: ", "), systemImage: "figure.arms.open")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            
            if showingFullPlan {
                expandedWorkoutPlanView(session)
            }
        }
    }
    
    private func expandedWorkoutPlanView(_ session: ActivitySession) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(session.activityGroups.enumerated()), id: \.offset) { groupIndex, group in
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Image(systemName: group.activity.icon)
                            .font(.caption)
                            .foregroundColor(Color("AccentColor"))
                        
                        Text(group.activity.displayName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Text("(\(group.location.displayName))")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                    }
                    
                    ForEach(Array(group.workouts.enumerated()), id: \.offset) { workoutIndex, workout in
                        WorkoutPlanCard(workout: workout, index: workoutIndex + 1)
                    }
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var noCustomWorkoutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "minus.circle")
                    .foregroundColor(.secondary)
                    .font(.caption)
                
                Text("Custom Workout")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
            }
            
            Text("No custom workout plan applied")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
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
            
        } catch {
            print("Error loading workout details: \(error)")
        }
        
        isLoadingDetails = false
    }
    
    private func calculateAverageHeartRate() -> Double? {
        guard !heartRateData.isEmpty else { return nil }
        return heartRateData.reduce(0, +) / Double(heartRateData.count)
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

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.caption)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct ActivityMetricsCard: View {
    let metrics: ActivityMetrics
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Interval \(index)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(formatTimeRange(start: metrics.startDate, end: metrics.endDate))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 8) {
                if let duration = metrics.duration {
                    MetricItem(
                        title: "Duration",
                        value: formatDuration(duration),
                        icon: "clock"
                    )
                }
                
                if let calories = metrics.calories {
                    MetricItem(
                        title: "Calories",
                        value: "\(Int(calories)) kcal",
                        icon: "flame"
                    )
                }
                
                if let distance = metrics.distance {
                    MetricItem(
                        title: "Distance",
                        value: formatDistance(distance),
                        icon: "location"
                    )
                }
                
                if let pace = metrics.pace {
                    MetricItem(
                        title: "Pace",
                        value: formatPace(pace),
                        icon: "speedometer"
                    )
                }
                
                if let avgHR = metrics.avgHR {
                    MetricItem(
                        title: "Avg HR",
                        value: "\(Int(avgHR)) bpm",
                        icon: "heart"
                    )
                }
                
                if let minHR = metrics.minHR, let maxHR = metrics.maxHR {
                    MetricItem(
                        title: "HR Range",
                        value: "\(Int(minHR))-\(Int(maxHR))",
                        icon: "arrow.up.arrow.down"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatTimeRange(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
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
}

struct MetricItem: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(Color("AccentColor"))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text(value)
                    .font(.caption)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct WorkoutPlanCard: View {
    let workout: Workout
    let index: Int
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Workout \(index)")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(Color("AccentColor"))
                
                if let workoutType = workout.workoutType {
                    Text(workoutType.rawValue)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if workout.iterations > 1 {
                    Text("\(workout.iterations) sets")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            // Target information
            if !workout.targetMetrics.isEmpty || !workout.targetMuscles.isEmpty {
                HStack(spacing: 12) {
                    if !workout.targetMetrics.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(workout.targetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    
                    if !workout.targetMuscles.isEmpty {
                        HStack(spacing: 4) {
                            Image(systemName: "figure.arms.open")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            Text(workout.targetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                }
            }
            
            // Exercises
            ForEach(Array(workout.exercises.enumerated()), id: \.offset) { exerciseIndex, exercise in
                HStack(spacing: 6) {
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(Color("AccentColor"))
                    
                    Text(exercise.displayName)
                        .font(.caption2)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Text(goalDescription(exercise.goal))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                
                // Show rest period if available
                if exerciseIndex < workout.restPeriods.count {
                    let rest = workout.restPeriods[exerciseIndex]
                    HStack(spacing: 6) {
                        Text("  ↳")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Text(rest.displayName)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Text(goalDescription(rest.goal))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
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

#Preview {
    NavigationView {
        WorkoutView(workout: HKWorkout(
            activityType: .running,
            start: Date().addingTimeInterval(-3600),
            end: Date()
        ))
    }
} 
