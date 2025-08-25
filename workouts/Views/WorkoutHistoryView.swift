import SwiftUI
import HealthKit
import Foundation

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
}