//
//  WorkoutPreviewView.swift
//  workouts
//
//  Created by Andrés on 5/4/2025.
//

import SwiftUI
import WorkoutKit

struct WorkoutPreviewView: View {
    let workout: CustomWorkout
    @State private var showWorkout: Bool = false
    @State private var scheduledDate: Date = Date()
    @State private var scheduledWorkoutPlan: ScheduledWorkoutPlan = {
        let defaultWorkoutPlan = WorkoutPlan(
            .custom(CustomWorkout(
                activity: .functionalStrengthTraining,
                location: .indoor,
                displayName: "Default Workout"
            )), 
            id: UUID()
        )
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: Date())
        return ScheduledWorkoutPlan(defaultWorkoutPlan, date: dateComponents)
    }()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
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
                    // Workout Header
                    VStack(spacing: 8) {
                        Text(workout.displayName ?? "Workout")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundStyle(.primary)
                    }
                    .padding(.top)

                    // Workout Structure
                    VStack(spacing: 20) {
                        Text("Workout Structure")
                            .font(.title2)
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        workoutDetailsView
                    }
                    .padding(.horizontal)
                    
                    // Control Buttons
                    VStack(spacing: 15) {
                        Button(action: {
                            Task {
                                // Calculate a date that's 1 minute from now for scheduling
                                scheduledDate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
                                await scheduleWorkout()
                                showWorkout = true
                            }
                        }) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("Start Workout")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color("AccentColor"))
                            .foregroundColor(Color.black)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        
                        Button(action: {
                            dismiss()
                        }) {
                            Text("Cancel")
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .padding(.vertical, 20)
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutView(workout: workout, scheduledWorkout: scheduledWorkoutPlan)
        }
    }
    
    private var workoutDetailsView: some View {
        VStack(spacing: 15) {
            if let warmup = workout.warmup {
                workoutPhaseCard(
                    title: "Warmup",
                    step: warmup,
                    color: .orange,
                    icon: "flame.fill"
                )
            }
            
            ForEach(Array(workout.blocks.enumerated()), id: \.offset) { index, block in
                if let intervalBlock = block as? IntervalBlock {
                    VStack(spacing: 10) {
                        HStack {
                            Image(systemName: "repeat.circle.fill")
                                .font(.title2)
                                .foregroundStyle(Color("AccentColor"))
                            Text("Block \(index + 1) - \(intervalBlock.iterations)x")
                                .font(.headline)
                            Spacer()
                        }
                        
                        ForEach(Array(intervalBlock.steps.enumerated()), id: \.offset) { stepIndex, step in
                            if let intervalStep = step as? IntervalStep {
                                intervalStepView(intervalStep, color: Color("AccentColor"))
                            }
                        }
                        
                        if let duration = totalBlockDuration(intervalBlock) {
                            HStack {
                                Spacer()
                                Text("Total block time: \(timeString(from: duration))")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 15))
                }
            }
            
            if let cooldown = workout.cooldown {
                workoutPhaseCard(
                    title: "Cooldown",
                    step: cooldown,
                    color: .blue,
                    icon: "wind"
                )
            }
        }
    }
    
    private func intervalStepView(_ step: IntervalStep, color: Color) -> some View {
        let isRest = step.purpose == .recovery
        let stepColor = isRest ? Color.yellow : color
        
        return HStack(spacing: 15) {
            Image(systemName: isRest ? "zzz" : "dumbbell.fill")
                .font(.title3)
                .foregroundStyle(stepColor)
                .frame(width: 30)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(step.step.displayName ?? (isRest ? "Rest" : "Exercise"))
                        .font(.headline)
                }
                
                goalDescription(for: step.step.goal)
                
                if let alert = step.step.alert {
                    alertDescription(for: alert)
                }
            }
            Spacer()
        }
        .padding(.vertical, 8)
        .padding(.horizontal)
        .background(stepColor.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    
    private func workoutPhaseCard(title: String, step: WorkoutStep, color: Color, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                    .frame(width: 40)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                    goalDescription(for: step.goal)
                }
                
                Spacer()
            }
            
            if let alert = step.alert {
                alertDescription(for: alert)
                    .padding(.leading, 40)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func goalDescription(for goal: WorkoutGoal) -> Text {
        switch goal {
        case .time(let duration, let unit):
            return Text(timeString(from: duration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .distance(let distance, let unit):
            return Text(String(format: "%.1f %@", distance, unit.description))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .open:
            return Text("Until manually advanced")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        @unknown default:
            return Text("Unknown goal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
    
    private func alertDescription(for alert: any WorkoutAlert) -> some View {
        HStack {
            Image(systemName: "heart.fill")
                .foregroundStyle(.orange)
            Text("Target Zone Alert")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func totalBlockDuration(_ block: IntervalBlock) -> TimeInterval? {
        var totalDuration: TimeInterval = 0
        var hasTimeGoal = false
        
        for step in block.steps {
            if let intervalStep = step as? IntervalStep,
               case .time(let duration, _) = intervalStep.step.goal {
                hasTimeGoal = true
                totalDuration += duration
            }
        }
        
        return hasTimeGoal ? (totalDuration * Double(block.iterations)) : nil
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func scheduleWorkout() async {
        do {
            let workoutPlanWorkout = WorkoutPlan.Workout.custom(workout)
            let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())
            
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: scheduledDate)
            
            await WorkoutScheduler.shared.schedule(plan, at: dateComponents)
 
            let newScheduledWorkout = ScheduledWorkoutPlan(plan, date: dateComponents)
            scheduledWorkoutPlan = newScheduledWorkout
            
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
    
    return WorkoutPreviewView(workout: workout)
}
