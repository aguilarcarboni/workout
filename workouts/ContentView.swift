import SwiftUI
import WorkoutKit

struct ContentView: View {
    
    @State private var workoutManager: WorkoutManager = .shared
    @State private var notificationManager: NotificationManager = .shared
    @State private var workoutScheduler: WorkoutScheduler = .shared
    @State private var isLoading: Bool = true

    var body: some View {
        Group {
            if !isLoading {
                TabView {
                    WorkoutsView()
                    .tabItem {
                        Label("Workout", systemImage: "figure.strengthtraining.traditional")
                    }

                    RecoveryView()
                    .tabItem {
                        Label("Recovery", systemImage: "figure.mind.and.body")
                    }
                    
                    ScheduledWorkoutsView()
                    .tabItem {
                        Label("Scheduled", systemImage: "clock")
                    }
                    
                }
            } else {
                ProgressView()
            }
        }
        .task {
            
            // Authenticate Relevant Services
            _ = await workoutScheduler.requestAuthorization()
            await notificationManager.requestAuthorization()
            
            // Prepare Workouts
            await removeAllScheduledWorkoutsScheduledBeforeToday()
            await workoutManager.createWorkouts()
            self.isLoading = false
            
        }
    }

    private func removeAllScheduledWorkoutsScheduledBeforeToday() async {
        let scheduledWorkouts = await workoutScheduler.scheduledWorkouts
        let today = Date()
        let calendar = Calendar.current
        for scheduledWorkout in scheduledWorkouts {
            if let scheduledDate = calendar.date(from: scheduledWorkout.date), scheduledDate < today {
                await workoutScheduler.remove(scheduledWorkout.plan, at: scheduledWorkout.date)
            }
        }
    }
}
