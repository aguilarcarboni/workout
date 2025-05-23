//
//  WorkoutPreviewView.swift
//  workouts
//
//  Created by Andrés on 5/4/2025.
//

import SwiftUI
import WorkoutKit
import HealthKit

struct WorkoutPreviewView: View {

    @State private var notificationManager: NotificationManager = .shared
    let workoutSequence: WorkoutSequence

    @Environment(\.dismiss) private var dismiss

    private func scheduleWorkoutSequence() async {
        
        var currentDate = Date()
        
        // Add safety check for empty workout sequence
        guard !workoutSequence.workouts.isEmpty else {
            fatalError("No workouts in sequence")
        }
        
        for workout in workoutSequence.workouts {
            do {

                let workoutPlanWorkout = WorkoutPlan.Workout.custom(workout)
                let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())

                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
                
                await WorkoutScheduler.shared.schedule(plan, at: dateComponents)
                currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate

                // Send notification for the workout
                let scheduledWorkout = ScheduledWorkoutPlan(plan, date: dateComponents)
                notificationManager.sendWorkoutNotification(scheduledWorkoutPlan: scheduledWorkout)
                
            } catch {
                fatalError("Failed to schedule workout: \(error)")
            }
        }

    }

    // Views
    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
        .padding(.vertical, 20)
    }
    
    private var backgroundGradient: some View {
        LinearGradient(
            gradient: Gradient(colors: [
                Color(.systemBackground),
                Color(.systemBackground).opacity(0.8)
            ]),
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
    
    private var mainContent: some View {
        ScrollView {
            VStack(spacing: 25) {
                headerView
                workoutSequenceView
                controlButtons
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(workoutSequence.displayName)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text("\(workoutSequence.workouts.count) workout\(workoutSequence.workouts.count == 1 ? "" : "s") in sequence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var workoutSequenceView: some View {
        VStack(spacing: 30) {
            ForEach(0..<workoutSequence.workouts.count, id: \.self) { index in
                let workout = workoutSequence.workouts[index]
                workoutView(for: workout, at: index)
            }
        }
    }
    
    private func workoutView(for workout: CustomWorkout, at index: Int) -> some View {
        VStack(spacing: 20) {
            HStack {
                Image(systemName: iconForActivityType(workout.activity))
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                Text("\(workout.displayName ?? "Unnamed Workout")")
                    .font(.title2)
                    .fontWeight(.bold)
            }
            
            workoutDetailsView(for: workout)
        }
        .padding(.horizontal)
    }
    
    private var controlButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                Task {
                    await scheduleWorkoutSequence()
                    dismiss()
                }
            }) {
                HStack {
                    Image(systemName: "applewatch")
                    Text("Send to Watch")
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
    
    private func workoutDetailsView(for workout: CustomWorkout) -> some View {
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
                    intervalBlockView(intervalBlock, blockIndex: index)
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
    
    private func intervalBlockView(_ block: IntervalBlock, blockIndex: Int) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                Text("\(block.iterations) set\(block.iterations > 1 ? "s" : "")")
                    .font(.headline)
                Spacer()
            }
            
            ForEach(Array(block.steps.enumerated()), id: \.offset) { stepIndex, step in
                if let intervalStep = step as? IntervalStep {
                    intervalStepView(intervalStep, color: Color("AccentColor"))
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
    
    private func intervalStepView(_ step: IntervalStep, color: Color) -> some View {
        let isRest = step.purpose == .recovery
        let stepColor = isRest ? Color.yellow : color
        
        return HStack(spacing: 15) {

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

    private func alertDescription(for alert: any WorkoutAlert) -> some View {
        HStack {
            Image(systemName: alertIcon(for: alert))
                .foregroundStyle(alertColor(for: alert))
            Text(alertDescription(for: alert))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // Mappers
    private func alertIcon(for alert: any WorkoutAlert) -> String {
        switch alert {
        case is HeartRateRangeAlert, is HeartRateZoneAlert:
            return "heart.fill"
        case is PowerRangeAlert, is PowerThresholdAlert, is PowerZoneAlert:
            return "bolt.fill"
        case is CadenceRangeAlert, is CadenceThresholdAlert:
            return "figure.run"
        case is SpeedRangeAlert, is SpeedThresholdAlert:
            return "speedometer"
        default:
            return "bell.fill"
        }
    }
    
    private func alertColor(for alert: any WorkoutAlert) -> Color {
        switch alert {
        case is HeartRateRangeAlert, is HeartRateZoneAlert:
            return .red
        case is PowerRangeAlert, is PowerThresholdAlert, is PowerZoneAlert:
            return .yellow
        case is CadenceRangeAlert, is CadenceThresholdAlert:
            return .green
        case is SpeedRangeAlert, is SpeedThresholdAlert:
            return .blue
        default:
            return .orange
        }
    }
    
    private func alertDescription(for alert: any WorkoutAlert) -> String {
        switch alert {
        case let heartRateAlert as HeartRateRangeAlert:
            let lowerBound = heartRateAlert.target.lowerBound.value
            let upperBound = heartRateAlert.target.upperBound.value
            return "Heart Rate: \(Int(lowerBound))-\(Int(upperBound)) BPM"
        case let heartRateAlert as HeartRateZoneAlert:
            return "Heart Rate Zone: \(heartRateAlert.zone)"
        case let powerAlert as PowerRangeAlert:
            let lowerBound = powerAlert.target.lowerBound.value
            let upperBound = powerAlert.target.upperBound.value
            return "Power: \(Int(lowerBound))-\(Int(upperBound)) W"
        case let powerAlert as PowerThresholdAlert:
            return "Power: \(Int(powerAlert.target.value)) W"
        case let powerAlert as PowerZoneAlert:
            return "Power Zone: \(powerAlert.zone)"
        case let cadenceAlert as CadenceRangeAlert:
            let lowerBound = cadenceAlert.target.lowerBound.value
            let upperBound = cadenceAlert.target.upperBound.value
            return "Cadence: \(Int(lowerBound))-\(Int(upperBound)) RPM"
        case let cadenceAlert as CadenceThresholdAlert:
            return "Cadence: \(Int(cadenceAlert.target.value)) RPM"
        case let speedAlert as SpeedRangeAlert:
            let lowerBound = speedAlert.target.lowerBound.value
            let upperBound = speedAlert.target.upperBound.value
            return "Speed: \(String(format: "%.1f", lowerBound))-\(String(format: "%.1f", upperBound)) \(speedAlert.target.lowerBound.unit.symbol)"
        case let speedAlert as SpeedThresholdAlert:
            return "Speed: \(String(format: "%.1f", speedAlert.target.value)) \(speedAlert.target.unit.symbol)"
        default:
            return "Target Zone Alert"
        }
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
            return Text("No goal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        @unknown default:
            return Text("Unknown goal")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
