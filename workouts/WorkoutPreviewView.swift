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
    let workoutSequence: WorkoutSequence
    @State private var showWorkout: Bool = false
    @State private var s: Int = 0
    @State private var scheduledDate: Date = Date()
    @State private var scheduledWorkoutPlans: [ScheduledWorkoutPlan] = []
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        ZStack {
            backgroundGradient
            mainContent
        }
        .padding(.vertical, 20)
        .fullScreenCover(isPresented: $showWorkout) {
            if !scheduledWorkoutPlans.isEmpty {
                WorkoutView(workoutSequence: workoutSequence, scheduledWorkouts: scheduledWorkoutPlans)
            }
        }
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
            
            Text("\(workoutSequence.workouts.count) workouts in sequence")
                .font(.subheadline)
                .foregroundStyle(.secondary)
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
                Spacer()
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
                if block.iterations > 1 {
                    Image(systemName: "repeat.circle.fill")
                        .font(.title2)
                        .foregroundStyle(Color("AccentColor"))
                    Text("\(block.iterations) sets")
                        .font(.headline)
                }
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

    // Alerts
    private func alertDescription(for alert: any WorkoutAlert) -> some View {
        HStack {
            Image(systemName: alertIcon(for: alert))
                .foregroundStyle(alertColor(for: alert))
            Text(alertDescription(for: alert))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
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

    // Goals
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

    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func scheduleWorkoutSequence() async {
        scheduledWorkoutPlans.removeAll()
        var currentDate = scheduledDate
        
        // Add safety check for empty workout sequence
        guard !workoutSequence.workouts.isEmpty else {
            print("No workouts in sequence")
            return
        }
        
        for workout in workoutSequence.workouts {
            do {
                let workoutPlanWorkout = WorkoutPlan.Workout.custom(workout)
                let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())
                
                let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: currentDate)
                
                await WorkoutScheduler.shared.schedule(plan, at: dateComponents)
                
                let scheduledWorkout = ScheduledWorkoutPlan(plan, date: dateComponents)
                scheduledWorkoutPlans.append(scheduledWorkout)
                
                // Add 5 minutes for the next workout
                currentDate = Calendar.current.date(byAdding: .minute, value: 5, to: currentDate) ?? currentDate
                
                print("Workout \(scheduledWorkoutPlans.count) of \(workoutSequence.workouts.count) scheduled successfully")
            } catch {
                print("Failed to schedule workout: \(error)")
            }
        }
        
        // Only show workout view if we have successfully scheduled workouts
        guard !scheduledWorkoutPlans.isEmpty else {
            print("No workouts were scheduled")
            return
        }
        
        // Verify counts match
        guard scheduledWorkoutPlans.count == workoutSequence.workouts.count else {
            print("Warning: Not all workouts were scheduled successfully")
            return
        }
        
        showWorkout = true
    }
    
    private func iconForActivityType(_ activityType: HKWorkoutActivityType) -> String {
        switch activityType {
        case .archery: return "figure.archery"
        case .bowling: return "figure.bowling"
        case .fencing: return "figure.fencing"
        case .gymnastics: return "figure.gymnastics"
        case .trackAndField: return "figure.track.and.field"
        case .americanFootball: return "figure.american.football"
        case .australianFootball: return "figure.australian.football"
        case .baseball: return "figure.baseball"
        case .basketball: return "figure.basketball"
        case .cricket: return "figure.cricket"
        case .discSports: return "figure.disc.sports"
        case .handball: return "figure.handball"
        case .hockey: return "figure.hockey"
        case .lacrosse: return "figure.lacrosse"
        case .rugby: return "figure.rugby"
        case .soccer: return "figure.outdoor.soccer"
        case .softball: return "figure.softball"
        case .volleyball: return "figure.volleyball"
        case .preparationAndRecovery: return "figure.cooldown"
        case .flexibility: return "figure.flexibility"
        case .cooldown: return "figure.cooldown"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .wheelchairWalkPace: return "figure.roll"
        case .wheelchairRunPace: return "figure.roll.runningpace"
        case .cycling: return "figure.outdoor.cycle"
        case .handCycling: return "figure.hand.cycling"
        case .coreTraining: return "figure.core.training"
        case .elliptical: return "figure.elliptical"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .crossTraining: return "figure.cross.training"
        case .mixedCardio: return "figure.mixed.cardio"
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .jumpRope: return "figure.jumprope"
        case .stairClimbing: return "figure.stair.stepper"
        case .stairs: return "figure.stairs"
        case .stepTraining: return "figure.step.training"
        case .fitnessGaming: return "gamecontroller"
        case .barre: return "figure.barre"
        case .cardioDance: return "figure.dance"
        case .socialDance: return "figure.socialdance"
        case .yoga: return "figure.yoga"
        case .mindAndBody: return "figure.mind.and.body"
        case .pilates: return "figure.pilates"
        case .badminton: return "figure.badminton"
        case .pickleball: return "figure.pickleball"
        case .racquetball: return "figure.racquetball"
        case .squash: return "figure.squash"
        case .tableTennis: return "figure.table.tennis"
        case .tennis: return "figure.tennis"
        case .climbing: return "figure.climbing"
        case .equestrianSports: return "figure.equestrian.sports"
        case .fishing: return "figure.fishing"
        case .golf: return "figure.golf"
        case .hiking: return "figure.hiking"
        case .hunting: return "figure.hunting"
        case .play: return "figure.play"
        case .crossCountrySkiing: return "figure.skiing.crosscountry"
        case .curling: return "figure.curling"
        case .downhillSkiing: return "figure.skiing.downhill"
        case .snowSports: return "figure.snowboarding"
        case .snowboarding: return "figure.snowboarding"
        case .skatingSports: return "figure.ice.skating"
        case .paddleSports: return "figure.surfing"
        case .rowing: return "figure.indoor.rowing"
        case .sailing: return "figure.sailing"
        case .surfingSports: return "figure.surfing"
        case .swimming: return "figure.pool.swim"
        case .waterFitness: return "figure.water.fitness"
        case .waterPolo: return "figure.waterpolo"
        case .waterSports: return "figure.water.fitness"
        case .boxing: return "figure.boxing"
        case .kickboxing: return "figure.kickboxing"
        case .martialArts: return "figure.martial.arts"
        case .taiChi: return "figure.taichi"
        case .wrestling: return "figure.wrestling"
        case .swimBikeRun: return "figure.cross.training"
        case .transition: return "arrow.triangle.2.circlepath"
        case .underwaterDiving: return "figure.pool.swim"
        case .other: return "figure.walk"
        @unknown default: return "figure.walk"
        }
    }
}

// Extension to safely access array elements
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

#Preview {
    // Create a sample workout sequence for preview
    let warmupStep = WorkoutStep(goal: .time(120, .seconds))
    let benchPressStep = WorkoutStep(goal: .time(60, .seconds))
    let benchPressInterval = IntervalStep(.work, step: benchPressStep)
    let benchPressBlock = IntervalBlock(steps:[benchPressInterval], iterations: 3)
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
        displayName: "Cool Down",
        blocks: [benchPressBlock]
    )
    
    let sequence = WorkoutSequence(
        workouts: [workout1, workout2],
        displayName: "Sample Sequence"
    )
    
    return WorkoutPreviewView(workoutSequence: sequence)
}
