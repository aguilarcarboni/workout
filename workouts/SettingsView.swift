import SwiftUI
import HealthKit
import WorkoutKit

struct SettingsView: View {
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Button("Authorize Sync") {
                    Task {
                        await WorkoutScheduler.shared.requestAuthorization()
                    }
                }
                .buttonStyle(.bordered)
                .padding()
                
                Spacer()
            }
            .navigationTitle("Settings")
        }
    }
} 
