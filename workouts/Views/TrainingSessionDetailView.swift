import SwiftUI
import WorkoutKit
import HealthKit

struct TrainingSessionDetailView: View {
    @State private var notificationManager: NotificationManager = .shared
    @State private var expandedWorkouts: Set<String> = []
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
        NavigationStack {
            VStack {
                headerSection
                List {
                    
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
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button {
                                print(trainingSession.printableDescription())
                            } label: {
                                Image(systemName: "doc.text")
                            }
                            
                            Button {
                                Task {
                                    await scheduleTrainingSession()
                                    dismiss()
                                }
                            } label: {
                                Image(systemName: "applewatch")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color("AccentColor"))
                            .foregroundStyle(.black)
                        }
                    }
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
    }
    
    private var headerSection: some View {
        Section {
            VStack(alignment: .center, spacing: 12) {
                Text(trainingSession.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

            Text("TRAINING SESSION")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
            }
        }
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
    
    private func warmupSection(_ warmup: Warmup) -> some View {
        Section("Warmup") {
            ForEach(Array(warmup.workouts.enumerated()), id: \.offset) { index, workout in
                workoutRow(for: workout, icon: "figure.walk", workoutId: "warmup-\(index)")
            }
        }
    }
    
    private func workoutSequenceSection(_ sequence: WorkoutSequence, index: Int) -> some View {
        Section {
            ForEach(Array(sequence.workouts.enumerated()), id: \.offset) { workoutIndex, workout in
                workoutRow(for: workout, icon: sequence.activity.icon, workoutId: "sequence-\(index)-\(workoutIndex)")
            }
        } header: {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    HStack(spacing: 4) {
                        Image(systemName: sequence.activity.icon)
                            .font(.headline)
                            .foregroundStyle(Color("AccentColor"))
                        Text(sequence.activity.displayName)
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: sequence.location.icon)
                            .font(.caption)
                            .foregroundStyle(Color("AccentColor"))
                        Text(sequence.location.displayName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }
    
    private func cooldownSection(_ cooldown: Cooldown) -> some View {
        Section("Cooldown") {
            ForEach(Array(cooldown.workouts.enumerated()), id: \.offset) { index, workout in
                workoutRow(for: workout, icon: "figure.cooldown", workoutId: "cooldown-\(index)")
            }
        }
    }
    
    private func workoutRow(for workout: Workout, icon: String, workoutId: String) -> some View {
        let intervalBlock = workout.toWorkoutKitType()
        let isExpanded = expandedWorkouts.contains(workoutId)
        
        return VStack(alignment: .leading, spacing: 8) {
            Button(action: {
                if isExpanded {
                    expandedWorkouts.remove(workoutId)
                } else {
                    expandedWorkouts.insert(workoutId)
                }
            }) {
                HStack {
                    
                    VStack(alignment: .leading, spacing: 4) {
                        
                        HStack {
                            Image(systemName: "repeat")
                                .foregroundStyle(Color("AccentColor"))
                                .font(.caption)
                            Text("\(intervalBlock.iterations) set\(intervalBlock.iterations > 1 ? "s" : "")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            
                        }
                        
                        // Show target muscles
                        if !workout.targetMuscles.isEmpty {
                            HStack {
                                Image(systemName: "figure.arms.open")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(workout.targetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                        
                        // Show target fitness metrics
                        if !workout.targetMetrics.isEmpty {
                            HStack {
                                Image(systemName: "target")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(workout.targetMetrics.sorted { sortFitnessMetrics($0, $1) }.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
            }
            .buttonStyle(PlainButtonStyle())
            .foregroundColor(.primary)
            
            if isExpanded {
                exerciseDetailsView(for: intervalBlock, workout: workout)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func exerciseDetailsView(for block: IntervalBlock, workout: Workout) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(block.steps.enumerated()), id: \.offset) { stepIndex, step in
                if let intervalStep = step as? IntervalStep {
                    let exercise = getExerciseForStep(stepIndex, workout: workout)
                    intervalStepView(intervalStep, exercise: exercise)
                }
            }
        }
    }
    
    private func intervalStepView(_ step: IntervalStep, exercise: Exercise?) -> some View {
        let isRest = step.purpose == .recovery
        
        return VStack(alignment: .leading, spacing: 8) {

            // Show exercise-specific information if available
            if let exercise = exercise, !isRest {
                VStack(alignment: .leading, spacing: 4) {
                    // Movement information
                    HStack {
                        Text("\(exercise.movement.rawValue)")
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                    }
                    
                    // Target muscles
                    if !exercise.targetMuscles.isEmpty {
                        HStack {
                            Image(systemName: "figure.arms.open")
                                .font(.caption2)
                                .foregroundStyle(Color("AccentColor"))
                            Text("\(exercise.targetMuscles.sorted { $0.rawValue < $1.rawValue }.map { $0.rawValue }.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    // Target fitness metrics
                    if !exercise.targetMetrics.isEmpty {
                        HStack {
                            Image(systemName: "target")
                                .font(.caption2)
                                .foregroundStyle(Color("AccentColor"))
                            Text("\(exercise.targetMetrics.sorted { sortFitnessMetrics($0, $1) }.map { $0.rawValue }.joined(separator: ", "))")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.top, 2)
            } else {
                VStack(alignment: .leading, spacing: 4) {
                    // Movement information
                    HStack {
                        Text("Rest")
                            .font(.caption2)
                            .foregroundStyle(.primary)
                            .fontWeight(.semibold)
                    }
                    
                }
                .padding(.top, 2)
            }

            HStack {
                Image(systemName: "target")
                    .font(.caption2)
                    .foregroundStyle(Color("AccentColor"))
                    goalDescription(for: step.step.goal)
            }

            if let alert = step.step.alert {
                alertDescription(for: alert)
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isRest ? Color.black.opacity(0.05) : Color.black.opacity(0.1))
        .cornerRadius(8)
    }
    
    // MARK: - Helper Functions
    
    private func getAllTargetMetrics() -> Set<FitnessMetric> {
        var allMetrics: Set<FitnessMetric> = []
        
        // Add metrics from warmup
        if let warmup = trainingSession.warmup {
            for workout in warmup.workouts {
                allMetrics.formUnion(workout.targetMetrics)
            }
        }
        
        // Add metrics from workout sequences
        for sequence in trainingSession.workoutSequences {
            for workout in sequence.workouts {
                allMetrics.formUnion(workout.targetMetrics)
            }
        }
        
        // Add metrics from cooldown
        if let cooldown = trainingSession.cooldown {
            for workout in cooldown.workouts {
                allMetrics.formUnion(workout.targetMetrics)
            }
        }
        
        return allMetrics
    }
    
    private func sortFitnessMetrics(_ lhs: FitnessMetric, _ rhs: FitnessMetric) -> Bool {
        // Define a consistent order for fitness metrics
        let order: [FitnessMetric] = [
            .strength,
            .power,
            .speed,
            .endurance,
            .aerobicEndurance,
            .anaerobicEndurance,
            .muscularEndurance,
            .stability,
            .mobility,
            .agility
        ]
        
        let lhsIndex = order.firstIndex(of: lhs) ?? order.count
        let rhsIndex = order.firstIndex(of: rhs) ?? order.count
        
        return lhsIndex < rhsIndex
    }
    
    private func iconForFitnessMetric(_ metric: FitnessMetric) -> String {
        switch metric {
        case .strength:
            return "dumbbell.fill"
        case .stability:
            return "figure.mind.and.body"
        case .speed:
            return "speedometer"
        case .endurance, .aerobicEndurance, .anaerobicEndurance:
            return "heart.fill"
        case .muscularEndurance:
            return "figure.strengthtraining.traditional"
        case .agility:
            return "figure.run"
        case .power:
            return "bolt.fill"
        case .mobility:
            return "figure.flexibility"
        }
    }
    
    private func getExerciseForStep(_ stepIndex: Int, workout: Workout) -> Exercise? {
        // Since we alternate exercises and rest periods, we need to map step index to exercise
        let exerciseIndex = stepIndex / 2 // Integer division to get exercise index
        if stepIndex % 2 == 0 && exerciseIndex < workout.exercises.count {
            return workout.exercises[exerciseIndex]
        }
        return nil
    }
    
    private func alertDescription(for alert: any WorkoutAlert) -> some View {
        HStack {
            Image(systemName: alertIcon(for: alert))
                .foregroundStyle(alertColor(for: alert))
                .font(.caption)
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
            return .orange
        case is CadenceRangeAlert, is CadenceThresholdAlert:
            return .green
        case is SpeedRangeAlert, is SpeedThresholdAlert:
            return .blue
        default:
            return .gray
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
                .font(.caption)
                .foregroundStyle(.secondary)
        case .distance(let distance, let unit):
            return Text(String(format: "%.1f %@", distance, unit.symbol))
                .font(.caption)
                .foregroundStyle(.secondary)
        case .open:
            return Text("No goal")
                .font(.caption)
                .foregroundStyle(.secondary)
        @unknown default:
            return Text("Unknown goal")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        let minutes = Int(timeInterval) / 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
} 
