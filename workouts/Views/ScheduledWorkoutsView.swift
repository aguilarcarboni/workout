import SwiftUI
import WorkoutKit

struct ScheduledWorkoutsView: View {
    
    @State private var scheduledWorkouts: [ScheduledWorkoutPlan] = []
    @State private var workoutScheduler: WorkoutScheduler = .shared
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
                                scheduledWorkout: scheduledWorkout
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                
                                if scheduledWorkout.complete == false {
                                    Button {
                                        markComplete(scheduledWorkout)
                                    } label: {
                                        Label("Mark as Incomplete", systemImage: "xmark")
                                    }
                                    .tint(.blue)
                                }
                                Button {
                                    removeWorkout(at: IndexSet([scheduledWorkouts.firstIndex(of: scheduledWorkout)!]))
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                                .tint(.red)
                            }
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
        scheduledWorkouts = await workoutScheduler.scheduledWorkouts
        isLoading = false
    }
    
    private func markComplete(_ scheduledWorkout: ScheduledWorkoutPlan) {
        Task {
            await workoutScheduler.markComplete(
                scheduledWorkout.plan,
                at: scheduledWorkout.date
            )
            await loadScheduledWorkouts()
        }
    }
    
    private func removeWorkout(at offsets: IndexSet) {
        let workoutsToRemove = offsets.map { scheduledWorkouts[$0] }
        Task {
            for workout in workoutsToRemove {
                await workoutScheduler.remove(
                    workout.plan,
                    at: workout.date
                )
            }
            await loadScheduledWorkouts()
        }
    }
}

struct ScheduledWorkoutRow: View {
    let scheduledWorkout: ScheduledWorkoutPlan
    
    var body: some View {
        HStack {
            Image(systemName: scheduledWorkout.plan.workout.activity.icon)
                .font(.system(size: 24))
                .foregroundColor(.accent)
            VStack(alignment: .leading) {
                Text(scheduledWorkout.plan.workout.activity.name)
                    .font(.headline)
                if let date = Calendar.current.date(from: scheduledWorkout.date) {
                    Text(date, style: .date)
                        .font(.subheadline)
                    Text(date, style: .time)
                        .font(.subheadline)
                }
                if scheduledWorkout.complete == true {
                    Text("Completed")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
            }
            .padding(.vertical, 8)
        }  
    }
}
