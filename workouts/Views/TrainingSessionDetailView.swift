import SwiftUI
import WorkoutKit
import HealthKit

struct TrainingSessionDetailView: View {
    @State private var notificationManager: NotificationManager = .shared
    let trainingSession: TrainingSession
    @Environment(\.dismiss) private var dismiss
    
    private func scheduleTrainingSession() async {
        let customWorkouts = trainingSession.toWorkoutKitType()
        
        for (index, customWorkout) in customWorkouts.enumerated() {
            let workoutPlanWorkout = WorkoutPlan.Workout.custom(customWorkout)
            let plan = WorkoutPlan(workoutPlanWorkout, id: UUID())
            
            // Schedule workouts sequentially with some spacing
            let schedulingDate = Date().addingTimeInterval(TimeInterval(index * 300)) // 5 minutes apart
            let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: schedulingDate)
            
            await WorkoutScheduler.shared.schedule(plan, at: dateComponents)
            
            // Send notification for each workout
            let scheduledWorkout = ScheduledWorkoutPlan(plan, date: dateComponents)
            notificationManager.sendWorkoutNotification(scheduledWorkoutPlan: scheduledWorkout)
        }
    }
    
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
                trainingSessionContent
                controlButtons
            }
        }
    }
    
    private var headerView: some View {
        VStack(spacing: 8) {
            Text(trainingSession.displayName)
                .font(.system(size: 34, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
            
            Text(sessionDescription)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top)
    }
    
    private var sessionDescription: String {
        var components: [String] = []
        
        if trainingSession.warmup != nil {
            components.append("Warmup")
        }
        
        components.append("\(trainingSession.workoutSequences.count) sequence\(trainingSession.workoutSequences.count == 1 ? "" : "s")")
        
        if trainingSession.cooldown != nil {
            components.append("Cooldown")
        }
        
        return components.joined(separator: " • ")
    }
    
    private var trainingSessionContent: some View {
        VStack(spacing: 20) {
            // Warmup Section
            if let warmup = trainingSession.warmup {
                warmupSection(warmup)
            }
            
            // Main Workout Sequences
            ForEach(Array(trainingSession.workoutSequences.enumerated()), id: \.offset) { index, sequence in
                workoutSequenceSection(sequence, index: index)
            }
            
            // Cooldown Section
            if let cooldown = trainingSession.cooldown {
                cooldownSection(cooldown)
            }
        }
    }
    
    private func warmupSection(_ warmup: Warmup) -> some View {
        sessionPhaseView(
            title: warmup.displayName,
            workouts: warmup.workouts,
            color: .orange,
            icon: "figure.walk"
        )
    }
    
    private func workoutSequenceSection(_ sequence: WorkoutSequence, index: Int) -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: sequence.activity.icon)
                    .font(.title2)
                    .foregroundStyle(Color("AccentColor"))
                Text(sequence.displayName)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(Array(sequence.workouts.enumerated()), id: \.offset) { workoutIndex, workout in
                workoutView(for: workout)
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
    
    private func cooldownSection(_ cooldown: Cooldown) -> some View {
        sessionPhaseView(
            title: cooldown.displayName,
            workouts: cooldown.workouts,
            color: .blue,
            icon: "figure.cooldown"
        )
    }
    
    private func sessionPhaseView(title: String, workouts: [Workout], color: Color, icon: String) -> some View {
        VStack(spacing: 15) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(color)
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
            }
            .padding(.horizontal)
            
            ForEach(Array(workouts.enumerated()), id: \.offset) { index, workout in
                workoutView(for: workout)
            }
        }
        .padding()
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 15))
        .padding(.horizontal)
    }
    
    private func workoutView(for workout: Workout) -> some View {
        VStack(spacing: 15) {
            let intervalBlock = workout.toWorkoutKitType()
            intervalBlockView(intervalBlock)
        }
    }
    
    private func intervalBlockView(_ block: IntervalBlock) -> some View {
        VStack(spacing: 10) {
            HStack {
                Image(systemName: "repeat.circle.fill")
                    .font(.title3)
                    .foregroundStyle(Color("AccentColor"))
                Text("\(block.iterations) set\(block.iterations > 1 ? "s" : "")")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
            }
            
            ForEach(Array(block.steps.enumerated()), id: \.offset) { stepIndex, step in
                if let intervalStep = step as? IntervalStep {
                    intervalStepView(intervalStep)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
    
    private func intervalStepView(_ step: IntervalStep) -> some View {
        let isRest = step.purpose == .recovery
        let stepColor = isRest ? Color.yellow : Color("AccentColor")
        
        return HStack(spacing: 15) {
            VStack(alignment: .leading, spacing: 4) {
                Text(step.step.displayName ?? (isRest ? "Rest" : "Exercise"))
                    .font(.headline)
                
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
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    
    private var controlButtons: some View {
        VStack(spacing: 15) {
            Button(action: {
                Task {
                    await scheduleTrainingSession()
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
        }
        .padding(.horizontal)
        .padding(.bottom, 30)
    }
    
    // MARK: - Helper Functions
    
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
    
    private func goalDescription(for goal: WorkoutGoal) -> Text {
        switch goal {
        case .time(let duration, let unit):
            return Text(timeString(from: duration))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        case .distance(let distance, let unit):
            return Text(String(format: "%.1f %@", distance, unit.symbol))
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