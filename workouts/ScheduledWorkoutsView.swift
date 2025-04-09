import SwiftUI
import WorkoutKit

struct ScheduledWorkoutsView: View {
    @State private var scheduledWorkouts: [ScheduledWorkoutPlan] = []
    @State private var isLoading = true
    
    var body: some View {
        NavigationView {
            Group {
                if isLoading {
                    ProgressView()
                } else if scheduledWorkouts.isEmpty {
                    ContentUnavailableView(
                        "No Scheduled Workouts",
                        systemImage: "figure.run",
                        description: Text("Schedule a workout to see it here")
                    )
                } else {
                    List {
                        ForEach(scheduledWorkouts, id: \.plan.id) { scheduledWorkout in
                            ScheduledWorkoutRow(
                                scheduledWorkout: scheduledWorkout,
                                onMarkComplete: { 
                                    markComplete(scheduledWorkout)
                                },
                                onRemove: {
                                    removeWorkout(scheduledWorkout)
                                }
                            )
                        }
                    }
                }
            }
            .navigationTitle("Scheduled Workouts")
            .task {
                await loadScheduledWorkouts()
            }
            .refreshable {
                await loadScheduledWorkouts()
            }
        }
    }
    
    private func loadScheduledWorkouts() async {
        isLoading = true
        scheduledWorkouts = await WorkoutScheduler.shared.scheduledWorkouts
        isLoading = false
    }
    
    private func markComplete(_ scheduledWorkout: ScheduledWorkoutPlan) {
        Task {
            await WorkoutScheduler.shared.markComplete(
                scheduledWorkout.plan,
                at: scheduledWorkout.date
            )
            await loadScheduledWorkouts()
        }
    }
    
    private func removeWorkout(_ scheduledWorkout: ScheduledWorkoutPlan) {
        Task {
            await WorkoutScheduler.shared.remove(
                scheduledWorkout.plan,
                at: scheduledWorkout.date
            )
            await loadScheduledWorkouts()
        }
    }
}

struct ScheduledWorkoutRow: View {
    let scheduledWorkout: ScheduledWorkoutPlan
    let onMarkComplete: () -> Void
    let onRemove: () -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Workout")
                .font(.headline)
            
            if let date = Calendar.current.date(from: scheduledWorkout.date) {
                Text(date, style: .date)
                    .font(.subheadline)
                Text(date, style: .time)
                    .font(.subheadline)
            }
            
            HStack {
                
                Button("Remove", role: .destructive) {
                    onRemove()
                }
                .buttonStyle(.plain)
                .background(Color.red)
                .padding(15)
            }
            .padding(.top, 4)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ScheduledWorkoutsView()
} 
