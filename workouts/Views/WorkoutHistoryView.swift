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
                let recentWorkouts = Array(healthManager.workouts.prefix(5))
                if !recentWorkouts.isEmpty {
                    NavigationView {
                        RecentWorkoutsSummaryView(workouts: recentWorkouts)
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
