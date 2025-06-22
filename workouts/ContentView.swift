import SwiftUI
import SwiftData
import WorkoutKit

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var workoutManager: WorkoutManager = .shared
    @State private var notificationManager: NotificationManager = .shared
    @State private var workoutScheduler: WorkoutScheduler = .shared
    @State private var isLoading: Bool = true
    @State private var selectedTab: Int = 0

    var body: some View {
        Group {
            if !isLoading {
                TabView(selection: $selectedTab) {
                    ActivitySessionsView()
                    .tabItem {
                        Label("Workout", systemImage: "figure.strengthtraining.traditional")
                    }
                    .tag(0)

                    MindAndBodyView()
                    .tabItem {
                        Label("Mind and Body", systemImage: "figure.mind.and.body")
                    }
                    .tag(1)
                    
                }
                .accentColor(selectedTab == 0 ? Color.accentColor : Color("SecondaryAccentColor"))
            } else {
                ProgressView()
            }
        }
        .task {
            
            // Authenticate Relevant Services
            _ = await workoutScheduler.requestAuthorization()
            _ = await notificationManager.requestAuthorization()
            
            // Load workouts from SwiftData
            await removeAllScheduledWorkoutsScheduledBeforeToday()
            workoutManager.loadSessions(from: modelContext)
            self.isLoading = false
            
        }
    }

    private func removeAllScheduledWorkoutsScheduledBeforeToday() async {
        let scheduledWorkouts = await workoutScheduler.scheduledWorkouts
        let yesterday: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let calendar = Calendar.current
        for scheduledWorkout in scheduledWorkouts {
            if let scheduledDate = calendar.date(from: scheduledWorkout.date), scheduledDate < yesterday {
                await workoutScheduler.remove(scheduledWorkout.plan, at: scheduledWorkout.date)
            }
        }
    }
}
