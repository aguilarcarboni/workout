import SwiftUI
import HealthKit

struct WorkoutHistoryView: View {
    @StateObject private var healthManager = HealthManager.shared
    @State private var selectedWorkout: HKWorkout?
    @State private var showingSummary = false
    
    var body: some View {
        NavigationView {
            List(healthManager.workouts, id: \.uuid) { workout in
                WorkoutRowView(workout: workout)
                    .onTapGesture {
                        selectedWorkout = workout
                    }
            }
            .navigationTitle("Workout History")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingSummary = true
                    } label: {
                        Image(systemName: "text.append")
                            .foregroundColor(Color("AccentColor"))
                    }
                    .disabled(healthManager.workouts.isEmpty)
                }
            }
            .onAppear {
                if healthManager.isAuthorized {
                    healthManager.fetchWorkouts()
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                NavigationView {
                    WorkoutView(workout: workout)
                }
            }
            .sheet(isPresented: $showingSummary) {
                if let mostRecentWorkout = healthManager.workouts.first {
                    NavigationView {
                        WorkoutSummaryView(workout: mostRecentWorkout)
                    }
                }
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: HKWorkout
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: workout.workoutActivityType.icon)
                    .foregroundColor(.accentColor)
                Text(workout.workoutActivityType.displayName)
                    .font(.headline)
                Spacer()
                Text(workout.startDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
    
            Text(workout.startDate, style: .time)
                .font(.caption2)
                .foregroundColor(.secondary)

            Spacer()
            
            HStack {
                Label(formatDuration(workout.duration), systemImage: "clock")
                    .font(.caption)
                    .foregroundColor(.primary)
                
                if #available(iOS 18.0, *) {
                    if let calories = workout.statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie()) {
                        Label("\(Int(calories)) kcal", systemImage: "flame")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                } else {
                    if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                        Label("\(Int(calories)) kcal", systemImage: "flame")
                            .font(.caption)
                            .foregroundColor(.primary)
                    }
                }
                
                if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                    Label(formatDistance(distance), systemImage: "location")
                        .font(.caption)
                        .foregroundColor(.primary)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 2)
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
    
    private func formatDistance(_ distance: Double) -> String {
        if distance >= 1000 {
            return String(format: "%.1f km", distance / 1000)
        } else {
            return String(format: "%.0f m", distance)
        }
    }
}

#Preview {
    WorkoutHistoryView()
} 
