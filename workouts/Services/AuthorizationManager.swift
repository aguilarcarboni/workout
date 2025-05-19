import SwiftUI
import HealthKit
import WorkoutKit

class AuthorizationManager: ObservableObject {
    
    @Published var workoutAuthorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    @Published var healthAuthorizationState: WorkoutScheduler.AuthorizationState = .notDetermined
    
    static let shared = AuthorizationManager()
    
    func requestWorkoutAuthorization() async {
        await WorkoutScheduler.shared.requestAuthorization()
        workoutAuthorizationState = .authorized
    }

    func requestHealthAuthorization() async {
        await HealthManager.shared.requestAuthorization()
        healthAuthorizationState = .authorized
    }
} 
