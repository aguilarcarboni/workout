import SwiftUI
import WorkoutKit
import HealthKit

struct CreateTrainingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutManager: WorkoutManager
    
    @State private var sessionName = ""
    @State private var workoutSequences: [WorkoutSequenceBuilder] = [WorkoutSequenceBuilder()]
    @State private var hasWarmup = false
    @State private var hasCooldown = false
    @State private var warmupWorkouts: [WorkoutBuilder] = []
    @State private var cooldownWorkouts: [WorkoutBuilder] = []
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Training Session Details") {
                    TextField("Session Name", text: $sessionName)
                        .textInputAutocapitalization(.words)
                        .padding(.vertical, 2)
                }
                
                Section("Optional Components") {
                    Toggle("Include Warmup", isOn: $hasWarmup)
                        .padding(.vertical, 2)
                    Toggle("Include Cooldown", isOn: $hasCooldown)
                        .padding(.vertical, 2)
                }
                
                if hasWarmup {
                    Section("Warmup Workouts") {
                        ForEach(warmupWorkouts.indices, id: \.self) { index in
                            WorkoutBuilderRow(
                                workout: $warmupWorkouts[index],
                                onDelete: { warmupWorkouts.remove(at: index) }
                            )
                        }
                        Button("Add Warmup Workout") {
                            warmupWorkouts.append(WorkoutBuilder())
                        }
                        .padding(.top, 8)
                    }
                }
                
                Section("Main Workout Sequences") {
                    ForEach(workoutSequences.indices, id: \.self) { index in
                        WorkoutSequenceBuilderSection(
                            sequence: $workoutSequences[index],
                            onDelete: { workoutSequences.remove(at: index) }
                        )
                    }
                    
                    Button("Add Workout Sequence") {
                        workoutSequences.append(WorkoutSequenceBuilder())
                    }
                    .padding(.top, 8)
                }
                
                if hasCooldown {
                    Section("Cooldown Workouts") {
                        ForEach(cooldownWorkouts.indices, id: \.self) { index in
                            WorkoutBuilderRow(
                                workout: $cooldownWorkouts[index],
                                onDelete: { cooldownWorkouts.remove(at: index) }
                            )
                        }
                        Button("Add Cooldown Workout") {
                            cooldownWorkouts.append(WorkoutBuilder())
                        }
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle("New Training Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveTrainingSession()
                        dismiss()
                    }
                    .disabled(sessionName.isEmpty || workoutSequences.isEmpty || workoutSequences.contains { $0.workouts.isEmpty })
                }
            }
        }
    }
    
    private func saveTrainingSession() {
        let warmup = hasWarmup && !warmupWorkouts.isEmpty ? 
            Warmup(workouts: warmupWorkouts.compactMap { $0.buildWorkout() }, displayName: "Warmup") : nil
        
        let cooldown = hasCooldown && !cooldownWorkouts.isEmpty ?
            Cooldown(workouts: cooldownWorkouts.compactMap { $0.buildWorkout() }, displayName: "Cooldown") : nil
        
        let sequences = workoutSequences.compactMap { $0.buildWorkoutSequence() }
        
        let trainingSession = TrainingSession(
            warmup: warmup,
            workoutSequences: sequences,
            cooldown: cooldown,
            displayName: sessionName
        )
        
        workoutManager.addTrainingSession(trainingSession)
    }
}

// MARK: - Builder Classes

class WorkoutSequenceBuilder: ObservableObject {
    @Published var name = ""
    @Published var activity: HKWorkoutActivityType = .traditionalStrengthTraining
    @Published var location: HKWorkoutSessionLocationType = .indoor
    @Published var workouts: [WorkoutBuilder] = [WorkoutBuilder()]
    
    func buildWorkoutSequence() -> WorkoutSequence? {
        guard !name.isEmpty, !workouts.isEmpty else { return nil }
        
        let builtWorkouts = workouts.compactMap { $0.buildWorkout() }
        guard !builtWorkouts.isEmpty else { return nil }
        
        return WorkoutSequence(
            workouts: builtWorkouts,
            displayName: name,
            activity: activity,
            location: location
        )
    }
}

class WorkoutBuilder: ObservableObject {
    @Published var name = ""
    @Published var workoutType: WorkoutType? = nil
    @Published var iterations = 1
    @Published var exercises: [ExerciseBuilder] = [ExerciseBuilder()]
    @Published var restPeriods: [RestBuilder] = [RestBuilder()]
    
    func buildWorkout() -> Workout? {
        guard !name.isEmpty, !exercises.isEmpty else { return nil }
        
        let builtExercises = exercises.compactMap { $0.buildExercise() }
        guard !builtExercises.isEmpty else { return nil }
        
        let builtRestPeriods = restPeriods.map { $0.buildRest() }
        
        return Workout(
            exercises: builtExercises,
            restPeriods: builtRestPeriods,
            iterations: iterations,
            displayName: name,
            workoutType: workoutType
        )
    }
}

class ExerciseBuilder: ObservableObject {
    @Published var movement: Movement = .pullUps
    @Published var goalType: GoalType = .open
    @Published var timeValue: Double = 60
    @Published var distanceValue: Double = 1000
    @Published var distanceUnit: UnitLength = .meters
    
    enum GoalType: String, CaseIterable {
        case open = "Open"
        case time = "Time"
        case distance = "Distance"
    }
    
    func buildExercise() -> Exercise {
        let goal: WorkoutGoal
        switch goalType {
        case .open:
            goal = .open
        case .time:
            goal = .time(timeValue, .seconds)
        case .distance:
            goal = .distance(distanceValue, distanceUnit)
        }
        
        return Exercise(movement: movement, goal: goal)
    }
}

class RestBuilder: ObservableObject {
    @Published var name = "Rest"
    @Published var goalType: GoalType = .open
    @Published var timeValue: Double = 30
    
    enum GoalType: String, CaseIterable {
        case open = "Open"
        case time = "Time"
    }
    
    func buildRest() -> Rest {
        let goal: WorkoutGoal
        switch goalType {
        case .open:
            goal = .open
        case .time:
            goal = .time(timeValue, .seconds)
        }
        
        return Rest(displayName: name, goal: goal)
    }
}

// MARK: - UI Components

struct WorkoutSequenceBuilderSection: View {
    @Binding var sequence: WorkoutSequenceBuilder
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Sequence Name", text: $sequence.name)
                    .textInputAutocapitalization(.words)
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                .font(.caption)
            }
            
            Picker("Activity", selection: $sequence.activity) {
                Text("Strength Training").tag(HKWorkoutActivityType.traditionalStrengthTraining)
                Text("Cycling").tag(HKWorkoutActivityType.cycling)
                Text("Running").tag(HKWorkoutActivityType.running)
                Text("Core Training").tag(HKWorkoutActivityType.coreTraining)
                Text("HIIT").tag(HKWorkoutActivityType.highIntensityIntervalTraining)
                Text("Other").tag(HKWorkoutActivityType.other)
            }
            .pickerStyle(.menu)
            .padding(.vertical, 4)
            
            Picker("Location", selection: $sequence.location) {
                Text("Indoor").tag(HKWorkoutSessionLocationType.indoor)
                Text("Outdoor").tag(HKWorkoutSessionLocationType.outdoor)
            }
            .pickerStyle(.segmented)
            .padding(.vertical, 4)
            
            Text("Workouts")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.top, 12)
            
            ForEach(sequence.workouts.indices, id: \.self) { index in
                WorkoutBuilderRow(
                    workout: $sequence.workouts[index],
                    onDelete: { sequence.workouts.remove(at: index) }
                )
                .padding(.vertical, 4)
            }
            
            Button("Add Workout") {
                sequence.workouts.append(WorkoutBuilder())
            }
            .font(.caption)
            .padding(.top, 8)
        }
        .padding(.vertical, 8)
    }
}

struct WorkoutBuilderRow: View {
    @Binding var workout: WorkoutBuilder
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                TextField("Workout Name", text: $workout.name)
                    .textInputAutocapitalization(.words)
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                .font(.caption)
            }
            
            HStack {
                Picker("Type", selection: $workout.workoutType) {
                    Text("None").tag(WorkoutType?.none)
                    ForEach(WorkoutType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(WorkoutType?.some(type))
                    }
                }
                .pickerStyle(.menu)
                
                Stepper("Sets: \(workout.iterations)", value: $workout.iterations, in: 1...10)
                    .font(.caption)
            }
            .padding(.vertical, 4)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Exercises (\(workout.exercises.count))")
                        .font(.caption)
                        .fontWeight(.medium)
                    
                    Spacer()
                    
                    Button("Add Exercise") {
                        workout.exercises.append(ExerciseBuilder())
                        workout.restPeriods.append(RestBuilder())
                    }
                    .font(.caption2)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.mini)
                }
                .padding(.top, 4)
                
                ForEach(workout.exercises.indices, id: \.self) { index in
                    ExerciseBuilderRow(
                        exercise: $workout.exercises[index],
                        onDelete: { 
                            workout.exercises.remove(at: index)
                            if index < workout.restPeriods.count {
                                workout.restPeriods.remove(at: index)
                            }
                        }
                    )
                    .padding(.vertical, 2)
                }
            }
        }
        .padding(.leading, 8)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(Color.accentColor)
                .frame(width: 2)
        }
    }
}



struct ExerciseBuilderRow: View {
    @Binding var exercise: ExerciseBuilder
    let onDelete: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Picker("Movement", selection: $exercise.movement) {
                    ForEach(Movement.allCases, id: \.self) { movement in
                        Text(movement.rawValue).tag(movement)
                    }
                }
                .pickerStyle(.menu)
                .font(.caption)
                
                Spacer()
                
                Button("Delete", role: .destructive) {
                    onDelete()
                }
                .font(.caption2)
                .controlSize(.mini)
            }
            
            HStack {
                Picker("Goal", selection: $exercise.goalType) {
                    ForEach(ExerciseBuilder.GoalType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.segmented)
                .font(.caption2)
                
                switch exercise.goalType {
                case .open:
                    EmptyView()
                case .time:
                    Stepper("\(Int(exercise.timeValue))s", value: $exercise.timeValue, in: 5...3600, step: 5)
                        .font(.caption2)
                case .distance:
                    HStack {
                        Stepper("\(exercise.distanceValue, specifier: "%.0f")", value: $exercise.distanceValue, in: 10...10000, step: 10)
                            .font(.caption2)
                        
                        Picker("Unit", selection: $exercise.distanceUnit) {
                            Text("m").tag(UnitLength.meters)
                            Text("km").tag(UnitLength.kilometers)
                            Text("mi").tag(UnitLength.miles)
                        }
                        .pickerStyle(.menu)
                        .font(.caption2)
                    }
                }
            }
        }
        .padding(8)
        .background(Color(.systemGray6))
        .cornerRadius(8)
    }
}

struct RestBuilderRow: View {
    @Binding var rest: RestBuilder
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            TextField("Rest Name", text: $rest.name)
            
            Picker("Goal Type", selection: $rest.goalType) {
                ForEach(RestBuilder.GoalType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .pickerStyle(.segmented)
            
            if rest.goalType == .time {
                HStack {
                    Text("Duration:")
                    Stepper("\(Int(rest.timeValue))s", value: $rest.timeValue, in: 5...300, step: 5)
                }
            }
        }
    }
}

#Preview {
    CreateTrainingSessionView(workoutManager: WorkoutManager.shared)
} 