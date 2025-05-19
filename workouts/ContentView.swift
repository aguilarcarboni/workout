import SwiftUI
import WorkoutKit
import HealthKit

struct ContentView: View {
    var body: some View {
        TabView {

            WorkoutsView()
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }
            
            ScheduledWorkoutsView()
            .tabItem {
                Label("Scheduled", systemImage: "clock")
            }

            AnalysisView()
            .tabItem {
                Label("Analysis", systemImage: "chart.bar.fill")
            }
            
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
    }
}