import SwiftUI
import HealthKit
import WorkoutKit

struct AnalysisView: View {
    
    @StateObject private var healthManager = HealthManager.shared
    @State private var selectedWorkout: HKWorkout?
    @StateObject private var openAIService = OpenAIService()
    @State private var isShowingSummary = false
    
    
    
    var body: some View {
        NavigationView {
            List {
                ForEach(healthManager.workouts.sorted(by: { $0.startDate > $1.startDate }).prefix(10), id: \.uuid) { workout in
                    WorkoutRowView(workout: workout)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedWorkout = workout
                        }
                }
            }
            .onAppear {
                healthManager.fetchHealthData()
            }
            .navigationTitle("Analysis")
            .toolbar {
                ToolbarItem(placement: .automatic) {
                    Button(action: {
                        isShowingSummary = true
                    }) {
                        HStack {
                            Image(systemName: "text.append")
                                .font(.system(size: 16))
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                NavigationView {
                    CompletedWorkoutView(workout: workout)
                }
            }
            .sheet(isPresented: $isShowingSummary) {
                SummaryView(healthManager: healthManager)
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: HKWorkout
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(workout.workoutActivityType.name)
                .font(.headline)
            Text("Duration: \(formatDuration(workout.duration))")
                .font(.subheadline)
            if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                Text("Calories: \(Int(calories))")
                    .font(.subheadline)
            }
            Text("Date: \(workout.startDate.formatted(date: .abbreviated, time: .omitted))")
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "N/A"
    }
}

#Preview {
    AnalysisView()
}
