import SwiftUI
import WorkoutKit

struct WorkoutView: View {
    
    let workoutSequence: WorkoutSequence
    let scheduledWorkouts: [ScheduledWorkoutPlan]
    @State private var currentWorkoutIndex: Int = 0
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
    
    // Add safety checks to computed properties
    private var currentWorkout: CustomWorkout {
        guard currentWorkoutIndex < workoutSequence.workouts.count else {
            return workoutSequence.workouts[0] // Fallback to first workout
        }
        return workoutSequence.workouts[currentWorkoutIndex]
    }
    
    private var currentScheduledWorkout: ScheduledWorkoutPlan {
        guard currentWorkoutIndex < scheduledWorkouts.count else {
            return scheduledWorkouts[0] // Fallback to first scheduled workout
        }
        return scheduledWorkouts[currentWorkoutIndex]
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
            
            ScrollView {
                VStack(spacing: 25) {
                    // Sequence Header
                    VStack(spacing: 8) {
                        Text(workoutSequence.displayName)
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                        
                        Text("\(workoutSequence.workouts.count) workouts in sequence")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Workout Cards
                    ForEach(0..<workoutSequence.workouts.count, id: \.self) { index in
                        workoutCard(for: index)
                    }
                    
                    // Discard Button
                    Button(role: .destructive) {
                        discardWorkout()
                    } label: {
                        Text("Discard Sequence")
                            .foregroundColor(.white)
                            .padding(15)
                            .background(Color.red)
                            .cornerRadius(10)
                    }
                    .padding(.top)
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    private func workoutCard(for index: Int) -> some View {
        let workout = workoutSequence.workouts[index]
        let scheduledWorkout = scheduledWorkouts[index]
        
        return VStack(alignment: .leading, spacing: 15) {
            VStack(alignment: .leading, spacing: 8) {
                Text(workout.displayName ?? "Workout \(index + 1)")
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let date = Calendar.current.date(from: scheduledWorkout.date) {
                    Text("Scheduled for: \(formattedDate(date))")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            
            // Workout details
            workoutDetailsView(for: workout)
            
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
    
    private func workoutDetailsView(for workout: CustomWorkout) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            if let warmup = workout.warmup {
                phaseRow(name: "Warmup", icon: "flame.fill", color: .orange)
            }
            
            ForEach(0..<workout.blocks.count, id: \.self) { blockIndex in
                if let block = workout.blocks[blockIndex] as? IntervalBlock {
                    phaseRow(name: "Block \(blockIndex + 1)", icon: "repeat.circle.fill", color: Color("AccentColor"))
                }
            }
            
            if workout.cooldown != nil {
                phaseRow(name: "Cooldown", icon: "wind", color: .blue)
            }
        }
    }
    
    private func phaseRow(name: String, icon: String, color: Color) -> some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(color)
            Text(name)
                .font(.subheadline)
        }
    }
    
    private func discardWorkout() {
        Task {
            // Add safety check for scheduledWorkouts
            guard !scheduledWorkouts.isEmpty else {
                dismiss()
                return
            }
            
            for scheduledWorkout in scheduledWorkouts {
                await WorkoutScheduler.shared.remove(
                    scheduledWorkout.plan,
                    at: scheduledWorkout.date
                )
            }
            dismiss()
        }
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    // Create a sample workout sequence for preview
    let warmupStep = WorkoutStep(goal: .time(120, .seconds))
    let benchPressStep = WorkoutStep(goal: .time(60, .seconds))
    let restStep = WorkoutStep(goal: .time(30, .seconds))
    let benchPressInterval = IntervalStep(.work, step: benchPressStep)
    let restInterval = IntervalStep(.recovery, step: restStep)
    let benchPressBlock = IntervalBlock(steps:[benchPressInterval, restInterval], iterations: 3)
    let cooldownStep = WorkoutStep(goal: .time(60, .seconds))
    
    let workout1 = CustomWorkout(
        activity: .functionalStrengthTraining,
        location: .indoor,
        displayName: "Bench Press Workout",
        warmup: warmupStep,
        blocks: [benchPressBlock],
        cooldown: cooldownStep
    )
    
    let workout2 = CustomWorkout(
        activity: .functionalStrengthTraining,
        location: .indoor,
        displayName: "Squats",
        warmup: warmupStep,
        blocks: [benchPressBlock],
        cooldown: cooldownStep
    )
    
    let sequence = WorkoutSequence(workouts: [workout1, workout2], displayName: "Sample Sequence")
    
    let scheduledWorkouts = sequence.workouts.map { workout in
        let workoutPlanWorkout = WorkoutPlan.Workout.custom(workout)
        let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return ScheduledWorkoutPlan(plan, date: dateComponents)
    }
    
    return WorkoutView(workoutSequence: sequence, scheduledWorkouts: scheduledWorkouts)
} 
