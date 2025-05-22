import SwiftUI
import WorkoutKit

struct SettingsView: View {
    @State private var workoutScheduler: WorkoutScheduler = .shared
    
    @State private var isHealthAuthorized: Bool = false
    @State private var isWorkoutAuthorized: Bool = false
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                List {
                    Section("Authorization") {
                        Button(isWorkoutAuthorized ? "Watch Sync Authorized" : "Authorize Watch Sync") {
                            Task {
                                await workoutScheduler.requestAuthorization()
                                await refreshAuthorizationStates()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(isWorkoutAuthorized ? Color("AccentColor") : .primary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await refreshAuthorizationStates()
            }
        }
    }
    
    func refreshAuthorizationStates() async {
        if let workoutAuth = await getWorkoutAuthorization() {
            isWorkoutAuthorized = workoutAuth
        }
    }
    func getWorkoutAuthorization() async -> Bool? {
        // If authorizationState is @Published and not async, just check equality
        return workoutScheduler.authorizationState == .authorized
    }
}


#Preview {
    SettingsView()
}
