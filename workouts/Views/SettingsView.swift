import SwiftUI
import WorkoutKit

struct SettingsView: View {
    
    @State private var workoutScheduler: WorkoutScheduler = .shared
    @State private var notificationManager: NotificationManager = .shared

    @State private var workoutAuthorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    @State private var notificationAuthorizationState: UNAuthorizationStatus = .notDetermined
    
    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 20) {
                List {
                    Section("Authorization") {
                        Button(workoutAuthorizationState == .authorized ? "Watch Sync Authorized" : "Authorize Watch Sync") {
                            Task {
                                workoutAuthorizationState = await workoutScheduler.requestAuthorization()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(workoutAuthorizationState == .authorized ? Color("AccentColor") : .primary)
                    }
                    Section(header: Text("Notifications")) {
                        Button(notificationAuthorizationState == .authorized ? "Notifications Authorized" : "Authorize Notifications") {
                            Task {
                                notificationAuthorizationState = await notificationManager.requestAuthorization()
                            }
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(notificationAuthorizationState == .authorized ? Color("AccentColor") : .primary)
                    }
                }
            }
            .navigationTitle("Settings")
            .task {
                workoutAuthorizationState = await workoutScheduler.requestAuthorization()
                notificationAuthorizationState = await notificationManager.requestAuthorization()
            }
        }
    }
}