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
    @State private var intervalMappings: [IntervalMapping] = []
    @State private var matchedActivitySession: ActivitySession?
    @State private var isLoadingDetails = true
    @State private var showingSummary = false
    @State private var showingFullPlan = false

    // Dynamically build the list of available metrics so the grid has no empty spaces.
    private var workoutMetrics: [(title: String, value: String)] {
        var items: [(String, String)] = []

        // Always-present metrics
        items.append(("Workout Time", formatDuration(workout.duration)))
        items.append(("Elapsed Time", formatDuration(workout.duration + 42)))

        // Conditional metrics
        if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
            items.append(("Distance", formatDistance(distance)))
        }
        if let activeCalories = workout.activeCalories {
            items.append(("Active Calories", "\(Int(activeCalories))CAL"))
        }
        if let totalCalories = workout.totalCaloriesEstimate {
            items.append(("Total Calories", "\(Int(totalCalories))CAL"))
        }

        // Placeholder until cadence is available from data source
        items.append(("Avg. Cadence", "148SPM"))

        if let distance = workout.totalDistance?.doubleValue(for: .meter()), distance > 0 {
            let pace = workout.duration / (distance / 1000)
            items.append(("Avg. Pace", formatPace(pace)))
        }
        if let avgHR = heartRateData.averageHeartRate() {
            items.append(("Avg. Heart Rate", "\(Int(avgHR))BPM"))
        }

        return items
    }

    var body: some View {
        List {
            // Workout details grid section
            Section(header: Text("Workout Details")) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    ForEach(Array(workoutMetrics.enumerated()), id: \.offset) { _, metric in
                        WorkoutMetricView(
                            title: metric.title,
                            value: metric.value,
                            color: Color("AccentColor")
                        )
                    }
                }
            }
            .listSectionSeparator(.hidden)

            // Activity intervals shown as a list
            if !activityMetrics.isEmpty && !intervalMappings.isEmpty {
                Section(
                    header: Text("Activity Intervals")
                        .font(.headline)
                        .fontWeight(.semibold)
                ) {
                    // Data rows – one per recorded/planned interval
                    ForEach(intervalMappings, id: \.index) { mapping in
                        IntervalMetricsRowView(mapping: mapping)
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(workout.workoutActivityType.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingSummary = true
                } label: {
                    Image(systemName: "text.append")
                        .foregroundColor(Color("AccentColor"))
                }
            }
        }
        .sheet(isPresented: $showingSummary) {
            NavigationView {
                WorkoutSummaryView(workout: workout)
            }
        }
        .task {
            await loadWorkoutDetails()
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

            // Build mapping between plan steps and recorded intervals
            if let session = matchedActivitySession {
                intervalMappings = session.mapMetricsToPlan(for: workout.workoutActivityType, metrics: activityMetrics)
            } else {
                intervalMappings = []
            }
            
        } catch {
            print("Error loading workout details: \(error)")
        }
        
        isLoadingDetails = false
    }
}

struct WorkoutMetricView: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.primary)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
    }
}

struct IntervalMetricsRowView: View {
    let mapping: IntervalMapping

    var body: some View {
        HStack {
            // Interval label (either planned step name or generic index)
            Text(mapping.plannedStep?.displayName ?? "Interval \(mapping.index)")
                .font(.subheadline)
                .fontWeight(.medium)
                .frame(width: .infinity, alignment: .leading)

            Spacer()

            // Duration
            Text("")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(Color("AccentColor"))
                .frame(maxWidth: 100, alignment: .center)
        }
        .padding(.horizontal)
    }
}
