import SwiftUI
import WorkoutKit

struct ContentView: View {
    
    @State private var workoutManager: WorkoutManager = .shared
    @State private var workoutScheduler: WorkoutScheduler = .shared
    @State private var notificationManager: NotificationManager = .shared

    @State private var workoutAuthStatus: WorkoutScheduler.AuthorizationState = .notDetermined
    @State private var notificationAuthStatus: UNAuthorizationStatus = .notDetermined

    var body: some View {
        Group {
            if workoutAuthStatus == .authorized && notificationAuthStatus == .authorized {
                TabView {
                    WorkoutsView()
                    .tabItem {
                        Label("Workout", systemImage: "figure.strengthtraining.traditional")
                    }

                    NavigationView {
                        VStack {
                            Image(systemName: "figure.mind.and.body")
                            Text("Coming soon...")
                        }
                    }
                    .tabItem {
                        Label("Recovery", systemImage: "figure.mind.and.body")
                    }
                    
                    ScheduledWorkoutsView()
                    .tabItem {
                        Label("Scheduled", systemImage: "clock")
                    }
                    
                    SettingsView()
                    .tabItem {
                        Label("Settings", systemImage: "gear")
                    }
                }
            } else {
                VStack(spacing: 20) {
                    Text("Permissions Required")
                        .font(.title)
                    Text("This app requires permissions for workouts and notifications to function correctly. Please grant these permissions in the Settings app.")
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            }
        }
        .task {
            workoutAuthStatus = await workoutScheduler.requestAuthorization()
            notificationAuthStatus = await notificationManager.requestAuthorization()
            await workoutManager.createWorkouts()
            await removeAllScheduledWorkoutsScheduledBeforeToday()
        }
    }

    private func removeAllScheduledWorkoutsScheduledBeforeToday() async {
        let scheduledWorkouts = workoutScheduler.scheduledWorkouts
        let today = Date()
        let calendar = Calendar.current
        for scheduledWorkout in scheduledWorkouts {
            if let scheduledDate = calendar.date(from: scheduledWorkout.date), scheduledDate < today {
                await workoutScheduler.remove(scheduledWorkout.plan, at: scheduledWorkout.date)
            }
        }
    }
}
