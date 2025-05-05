import SwiftUI
import HealthKit
import WorkoutKit

struct SettingsView: View {
    @State private var authorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {

                List {
                    Section("Authorization") {
                        Button(authorizationState == .authorized ? "Authorized" : "Authorize Sync") {
                            Task {
                                authorizationState = await WorkoutScheduler.shared.requestAuthorization()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(authorizationState == .authorized ? Color("AccentColor") : .primary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                await updateAuthorizationState()
            }
        }
    }
    
    private func updateAuthorizationState() async {
        authorizationState = await WorkoutScheduler.shared.requestAuthorization()
    }
} 

#Preview {
    SettingsView()
}
