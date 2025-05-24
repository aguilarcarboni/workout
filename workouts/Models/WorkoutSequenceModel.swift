import SwiftUI
import WorkoutKit

struct WorkoutSequence: Identifiable {
    let id: String = UUID().uuidString
    let workouts: [CustomWorkout]
    let displayName: String
    
    init(workouts: [CustomWorkout], displayName: String) {
        self.workouts = workouts
        self.displayName = displayName
    }
}
