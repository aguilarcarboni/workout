import SwiftUI
import WorkoutKit

struct ContentView: View {
    var body: some View {
        TabView {
            WorkoutsView()
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }

            NavigationView {
                Image(systemName: "figure.mind.and.body")
                Text("Coming soon...")
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
    }
}