//
//  WorkoutView.swift
//  workouts
//
//  Created by Andrés on 5/4/2025.
//

import SwiftUI
import WorkoutKit

struct WorkoutView: View {
    let workout: CustomWorkout
    @State private var currentPhase: String = "Ready to start"
    @State private var timeRemaining: TimeInterval = 0
    @State private var isRunning: Bool = false
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(spacing: 20) {
            Text(workout.displayName!)
                .font(.largeTitle)
                .padding(.bottom, 10)
            
            Text("Current Phase: \(currentPhase)")
                .font(.title2)
            
            if timeRemaining > 0 {
                Text(timeString(from: timeRemaining))
                    .font(.system(size: 70, weight: .bold, design: .rounded))
                    .foregroundStyle(.blue)
                    .padding()
            }
            
            workoutDetailsView
            
            Button(isRunning ? "Pause Workout" : "Start Workout") {
                Task {
                    await scheduleWorkout()
                    dismiss()
                }
            }
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .padding()
    }
    
    private var workoutDetailsView: some View {
        VStack(alignment: .leading, spacing: 15) {
            GroupBox("Workout Structure") {
                VStack(alignment: .leading, spacing: 8) {
                    if let warmup = workout.warmup {
                        phaseRow(label: "Warmup", duration: goalDuration(warmup.goal))
                    }
                    
                    ForEach(Array(workout.blocks.enumerated()), id: \.offset) { index, block in
                        if let intervalBlock = block as? IntervalBlock {
                            phaseRow(label: "Block \(index + 1)", duration: totalBlockDuration(intervalBlock))
                        }
                    }
                    
                    if let cooldown = workout.cooldown {
                        phaseRow(label: "Cooldown", duration: goalDuration(cooldown.goal))
                    }
                }
                .padding(.vertical, 5)
            }
        }
        .frame(maxWidth: .infinity)
    }
    
    private func phaseRow(label: String, duration: TimeInterval) -> some View {
        HStack {
            Text(label)
                .fontWeight(.medium)
            Spacer()
            Text(timeString(from: duration))
                .foregroundStyle(.secondary)
        }
    }
    
    private func goalDuration(_ goal: WorkoutGoal) -> TimeInterval {
        switch goal {
        case .time(let duration, _):
            return duration
        default:
            return 0
        }
    }
    
    private func totalBlockDuration(_ block: IntervalBlock) -> TimeInterval {
        let singleIterationTime = block.steps.reduce(0) { result, step in
            if let intervalStep = step as? IntervalStep, 
               case .time(let duration, _) = intervalStep.step.goal {
                return result + duration
            }
            return result
        }
        return singleIterationTime * Double(block.iterations)
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    // Simulates a workout for preview purposes
    private func simulateWorkout() {
        // This would be replaced with actual workout tracking logic
        currentPhase = "Warmup"
        if let warmup = workout.warmup, case .time(let duration, _) = warmup.goal {
            timeRemaining = duration
        }
    }
    
    private func scheduleWorkout() async {
        do {
            let workoutPlanWorkout = WorkoutPlan.Workout.custom(workout)
            let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())
            
            var dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
            // Add a small buffer (1 minute) to ensure it's scheduled for the immediate future
            dateComponents.minute! += 1
            
            try await WorkoutScheduler.shared.schedule(plan, at: dateComponents)
            print("Workout scheduled successfully")
        } catch {
            print("Failed to schedule workout: \(error)")
        }
    }
}

#Preview {
    // Create a sample workout for preview
    let warmupStep = WorkoutStep(goal: .time(120, .seconds))
    let benchPressStep = WorkoutStep(goal: .time(60, .seconds))
    let benchPressInterval = IntervalStep(.work, step: benchPressStep)
    let benchPressBlock = IntervalBlock(steps:[benchPressInterval], iterations: 3)
    let cooldownStep = WorkoutStep(goal: .time(60, .seconds))
    
    let workout = CustomWorkout(
        activity: .functionalStrengthTraining,
        location: .indoor,
        displayName: "Bench Press Workout",
        warmup: warmupStep,
        blocks: [benchPressBlock],
        cooldown: cooldownStep
    )
    
    return WorkoutView(workout: workout)
} 
