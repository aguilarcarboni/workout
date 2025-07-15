import SwiftUI
import SwiftData
import WorkoutKit

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var workoutManager: WorkoutManager = .shared
    @State private var selectedTab: Int = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutSessionsView()
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }
            .tag(0)
            
            WorkoutHistoryView()
            .tabItem {
                Label("History", systemImage: "clock.arrow.circlepath")
            }
            .tag(1)
        }
        .accentColor(Color.accentColor)
    }
}
