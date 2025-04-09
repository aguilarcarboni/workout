import SwiftUI
import WorkoutKit

struct WorkoutView: View {
    let workout: CustomWorkout
    let scheduledWorkout: ScheduledWorkoutPlan
    @State private var currentPhase: String = "Warmup"
    @State private var currentPhaseIndex: Int = 0
    @State private var timeRemaining: TimeInterval = 0
    @State private var isRunning: Bool = true
    @State private var isWorkoutComplete: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    // Workout phases for tracking progress
    @State private var workoutPhases: [WorkoutPhase] = []
    
    struct WorkoutPhase {
        let name: String
        let duration: TimeInterval
        let color: Color
        let icon: String
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemBackground).opacity(0.8)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            VStack(spacing: 25) {
                // Workout Header
                VStack(spacing: 8) {
                    Text(workout.displayName ?? "Workout")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                        .foregroundStyle(.primary)
                    
                    Text(currentPhase)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    
                    Text("Scheduled for: \(formattedDate)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                }
                .padding(.top)
            }
            .padding(.vertical, 20)
        }
    }
    
    private var formattedDate: String {
        if let date = Calendar.current.date(from: scheduledWorkout.date) {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.timeStyle = .short
            return formatter.string(from: date)
        } else {
            return "Unknown date"
        }
    }
}

#Preview {
    // Create a sample workout for preview
    let warmupStep = WorkoutStep(goal: .time(120, .seconds))
    let benchPressStep = WorkoutStep(goal: .time(60, .seconds))
    let restStep = WorkoutStep(goal: .time(30, .seconds))
    let benchPressInterval = IntervalStep(.work, step: benchPressStep)
    let restInterval = IntervalStep(.recovery, step: restStep)
    let benchPressBlock = IntervalBlock(steps:[benchPressInterval, restInterval], iterations: 3)
    let cooldownStep = WorkoutStep(goal: .time(60, .seconds))
    
    let workout = CustomWorkout(
        activity: .functionalStrengthTraining,
        location: .indoor,
        displayName: "Bench Press Workout",
        warmup: warmupStep,
        blocks: [benchPressBlock],
        cooldown: cooldownStep
    )
    
    let workoutPlanWorkout = WorkoutPlan.Workout.custom(workout)
    let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())
    let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
    let scheduledWorkout = ScheduledWorkoutPlan(plan, date: dateComponents)
    
    return WorkoutView(workout: workout, scheduledWorkout: scheduledWorkout)
} 
