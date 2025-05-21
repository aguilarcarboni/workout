import SwiftUI
import HealthKit
import WorkoutKit

struct SettingsView: View {
    @State private var healthManager: HealthManager = .shared
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

                        Button(isHealthAuthorized ? "Health Data Authorized" : "Authorize Health Data") {
                            Task {
                                await healthManager.requestAuthorization()
                                await refreshAuthorizationStates()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(isHealthAuthorized ? Color("AccentColor") : .primary)
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
        // These may need to be replaced with actual async property fetches if available in your managers
        if let healthAuth = await getHealthAuthorization() {
            isHealthAuthorized = healthAuth
        }
        if let workoutAuth = await getWorkoutAuthorization() {
            isWorkoutAuthorized = workoutAuth
        }
    }
    
    // Example async fetchers. Replace with your actual async logic if needed.
    func getHealthAuthorization() async -> Bool? {
        // If isAuthorized is @Published and not async, just return it directly
        return healthManager.isAuthorized
    }
    func getWorkoutAuthorization() async -> Bool? {
        // If authorizationState is @Published and not async, just check equality
        return workoutScheduler.authorizationState == .authorized
    }
}


#Preview {
    SettingsView()
}
