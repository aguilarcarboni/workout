import SwiftUI
import SwiftData
import WorkoutKit

struct ContentView: View {
    
    @Environment(\.modelContext) private var modelContext
    @State private var workoutManager: WorkoutManager = .shared
    @State private var selectedTab: Int = 0

    var body: some View {
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
    }
}
