import SwiftUI
import HealthKit
import WorkoutKit

struct SettingsView: View {

    @StateObject private var authManager = AuthorizationManager.shared
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                List {
                    Section("Authorization") {
                        Button(authManager.workoutAuthorizationState == .authorized ? "Watch Sync Authorized" : "Authorize Watch Sync") {
                            Task {
                                await authManager.requestWorkoutAuthorization()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(authManager.workoutAuthorizationState == .authorized ? Color("AccentColor") : .primary)

                        Button(authManager.healthAuthorizationState == .authorized ? "Health Data Authorized" : "Authorize Health Data") {
                            Task {
                                await authManager.requestHealthAuthorization()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(authManager.healthAuthorizationState == .authorized ? Color("AccentColor") : .primary)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
} 

#Preview {
    SettingsView()
}
