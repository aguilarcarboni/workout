import SwiftUI
import WorkoutKit
import HealthKit

// MARK: - Create Training Session View

struct CreateTrainingSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var workoutManager: WorkoutManager
    
    @State private var sessionName = ""
    @State private var workoutSequences: [WorkoutSequence] = []
    @State private var hasWarmup = false
    @State private var hasCooldown = false
    @State private var warmupWorkouts: [Workout] = []
    @State private var cooldownWorkouts: [Workout] = []
    
    @State private var showingWorkoutSequenceCreator = false
    @State private var showingWarmupWorkoutCreator = false
    @State private var showingCooldownWorkoutCreator = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            Form {

                
                Section("Training Session Details") {
                    TextField("Session Name", text: $sessionName)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Optional Components") {
                    Toggle("Include Warmup", isOn: $hasWarmup)
                    Toggle("Include Cooldown", isOn: $hasCooldown)
                }
                
                if hasWarmup {
                    Section("Warmup Workouts") {
                        ForEach(warmupWorkouts.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Warmup Workout \(index + 1)")
                                        .font(.headline)
                                    Text("\(warmupWorkouts[index].exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Delete", role: .destructive) {
                                    warmupWorkouts.remove(at: index)
                                }
                                .font(.caption)
                            }
                        }
                        
                        Button("Add Warmup Workout") {
                            showingWarmupWorkoutCreator = true
                        }
                    }
                }
                
                Section("Main Workout Sequences") {
                    ForEach(workoutSequences.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("\(workoutSequences[index].activity.displayName) (\(workoutSequences[index].location.displayName))")
                                    .font(.headline)
                                Text("\(workoutSequences[index].workouts.count) workouts")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Delete", role: .destructive) {
                                workoutSequences.remove(at: index)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Button("Add Workout Sequence") {
                        showingWorkoutSequenceCreator = true
                    }
                }
                
                if hasCooldown {
                    Section("Cooldown Workouts") {
                        ForEach(cooldownWorkouts.indices, id: \.self) { index in
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Cooldown Workout \(index + 1)")
                                        .font(.headline)
                                    Text("\(cooldownWorkouts[index].exercises.count) exercises")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                Button("Delete", role: .destructive) {
                                    cooldownWorkouts.remove(at: index)
                                }
                                .font(.caption)
                            }
                        }
                        
                        Button("Add Cooldown Workout") {
                            showingCooldownWorkoutCreator = true
                        }
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
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Save") {
                            saveTrainingSession()
                            dismiss()
                        }
                        .disabled(sessionName.isEmpty || workoutSequences.isEmpty)
                    }
                }
            }
            .alert("Training Session Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("A Training Session is a complete workout for a single day. It's designed to target specific fitness goals and can include:\n\n• Warmup: Prepares your body for exercise, increases blood flow, and reduces injury risk\n• Main Workouts: The core training organized into sequences based on activity type\n• Cooldown: Helps your body recover and return to resting state\n\nEach component serves a specific purpose in your overall fitness development.")
            }
            .sheet(isPresented: $showingWorkoutSequenceCreator) {
                CreateWorkoutSequenceView { sequence in
                    workoutSequences.append(sequence)
                }
            }
            .sheet(isPresented: $showingWarmupWorkoutCreator) {
                CreateWorkoutView(title: "New Warmup Workout") { workout in
                    warmupWorkouts.append(workout)
                }
            }
            .sheet(isPresented: $showingCooldownWorkoutCreator) {
                CreateWorkoutView(title: "New Cooldown Workout") { workout in
                    cooldownWorkouts.append(workout)
                }
            }
        }
    }
    
    private func saveTrainingSession() {
        let warmup = hasWarmup && !warmupWorkouts.isEmpty ? 
            Warmup(workouts: warmupWorkouts, displayName: "Warmup") : nil
        
        let cooldown = hasCooldown && !cooldownWorkouts.isEmpty ?
            Cooldown(workouts: cooldownWorkouts, displayName: "Cooldown") : nil
        
        let trainingSession = TrainingSession(
            warmup: warmup,
            workoutSequences: workoutSequences,
            cooldown: cooldown,
            displayName: sessionName
        )
        
        workoutManager.addTrainingSession(trainingSession)
    }
}

// MARK: - Create Workout Sequence View

struct CreateWorkoutSequenceView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (WorkoutSequence) -> Void
    
    @State private var activity: HKWorkoutActivityType = .traditionalStrengthTraining
    @State private var location: HKWorkoutSessionLocationType = .indoor
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutCreator = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            Form {

                
                Section("Sequence Details") {
                    Picker("Activity Type", selection: $activity) {
                        Text("Strength Training").tag(HKWorkoutActivityType.traditionalStrengthTraining)
                        Text("Functional Strength Training").tag(HKWorkoutActivityType.functionalStrengthTraining)
                        Text("Cross Training").tag(HKWorkoutActivityType.crossTraining)
                        Text("Mixed Cardio").tag(HKWorkoutActivityType.mixedCardio)
                        Text("High Intensity Interval Training").tag(HKWorkoutActivityType.highIntensityIntervalTraining)
                        Text("Jump Rope").tag(HKWorkoutActivityType.jumpRope)
                        Text("Cycling").tag(HKWorkoutActivityType.cycling)
                        Text("Running").tag(HKWorkoutActivityType.running)
                        Text("Core Training").tag(HKWorkoutActivityType.coreTraining)
                        Text("HIIT").tag(HKWorkoutActivityType.highIntensityIntervalTraining)
                        Text("").tag(HKWorkoutActivityType.basketball)
                    }
                    
                    Picker("Location", selection: $location) {
                        Text("Indoor").tag(HKWorkoutSessionLocationType.indoor)
                        Text("Outdoor").tag(HKWorkoutSessionLocationType.outdoor)
                    }
                    .pickerStyle(.segmented)
                }
                
                Section("Workouts") {
                    ForEach(workouts.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Workout \(index + 1)")
                                    .font(.headline)
                                HStack {
                                    Text("\(workouts[index].exercises.count) exercises")
                                    if workouts[index].iterations > 1 {
                                        Text("• \(workouts[index].iterations) sets")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Delete", role: .destructive) {
                                workouts.remove(at: index)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Button("Add Workout") {
                        showingWorkoutCreator = true
                    }
                }
            }
            .navigationTitle("New Workout Sequence")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Save") {
                            let sequence = WorkoutSequence(
                                workouts: workouts,
                                activity: activity,
                                location: location
                            )
                            onSave(sequence)
                            dismiss()
                        }
                        .disabled(workouts.isEmpty)
                    }
                }
            }
            .alert("Workout Sequence Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("A Workout Sequence groups related workouts that share the same activity type and can be tracked together on your Apple Watch.\n\nActivity Types:\n• Strength Training: Weight lifting, resistance exercises\n• Cycling: Bike workouts, stationary or outdoor\n• Running: Cardio running activities\n• Core Training: Focused abdominal and core work\n• HIIT: High-intensity interval training\n• Other: General fitness activities\n\nLocation determines GPS tracking - use Indoor for gym workouts, Outdoor for running/cycling outside.")
            }
            .sheet(isPresented: $showingWorkoutCreator) {
                CreateWorkoutView(title: "New Workout") { workout in
                    workouts.append(workout)
                }
            }
        }
    }
}

// MARK: - Create Workout View

struct CreateWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    let title: String
    let onSave: (Workout) -> Void
    
    @State private var iterations = 1
    @State private var exercises: [Exercise] = []
    @State private var showingExerciseCreator = false
    @State private var showingHelp = false
    
    init(title: String = "New Workout", onSave: @escaping (Workout) -> Void) {
        self.title = title
        self.onSave = onSave
    }
    
    var body: some View {
        NavigationStack {
            Form {

                
                Section("Workout Details") {
                    Stepper("Sets: \(iterations)", value: $iterations, in: 1...10)
                }
                
                Section("Exercises") {
                    ForEach(exercises.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text(exercises[index].movement.rawValue)
                                    .font(.headline)
                                Text(goalDescription(exercises[index].goal))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Button("Delete", role: .destructive) {
                                exercises.remove(at: index)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Button("Add Exercise") {
                        showingExerciseCreator = true
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Save") {
                            let restPeriods = Array(repeating: Rest(), count: exercises.count)
                            let workout = Workout(
                                exercises: exercises,
                                restPeriods: restPeriods,
                                iterations: iterations,
                                workoutType: nil
                            )
                            onSave(workout)
                            dismiss()
                        }
                        .disabled(exercises.isEmpty)
                    }
                }
            }
            .alert("Workout Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("A Workout is simply a group of exercises performed together. The fitness goals and muscle targets are automatically determined by the exercises you include.\n\nJust add the exercises you want to perform, and the workout will automatically target the appropriate fitness metrics based on those movements.\n\nSets determine how many times you'll repeat the entire workout. More sets = higher training volume.")
            }
            .sheet(isPresented: $showingExerciseCreator) {
                CreateExerciseView { exercise in
                    exercises.append(exercise)
                }
            }
        }
    }
    
    private func goalDescription(_ goal: WorkoutGoal) -> String {
        switch goal {
        case .time(let duration, _):
            let minutes = Int(duration) / 60
            let seconds = Int(duration) % 60
            return "Goal: \(String(format: "%02d:%02d", minutes, seconds))"
        case .distance(let distance, let unit):
            return "Goal: \(String(format: "%.1f %@", distance, unit.symbol))"
        case .open:
            return "Goal: Open"
        @unknown default:
            return "Goal: Unknown"
        }
    }
}

// MARK: - Create Exercise View

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Exercise) -> Void
    
    @State private var movement: Movement = .pullUps
    @State private var goalType: GoalType = .open
    @State private var timeValue: Double = 60
    @State private var distanceValue: Double = 1000
    @State private var distanceUnit: UnitLength = .meters
    @State private var showingHelp = false
    
    enum GoalType: String, CaseIterable {
        case open = "Open"
        case time = "Time"
        case distance = "Distance"
    }
    
    var body: some View {
        NavigationStack {
            Form {

                
                Section("Exercise Details") {
                    Picker("Movement", selection: $movement) {
                        ForEach(Movement.allCases, id: \.self) { movement in
                            Text(movement.rawValue).tag(movement)
                        }
                    }
                }
                
                Section("Goal") {
                    Picker("Goal Type", selection: $goalType) {
                        ForEach(GoalType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    switch goalType {
                    case .open:
                        Text("Exercise will be open-ended")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    case .time:
                        Stepper("Duration: \(Int(timeValue)) seconds", value: $timeValue, in: 5...3600, step: 5)
                    case .distance:
                        HStack {
                            Stepper("Distance: \(distanceValue, specifier: "%.0f")", value: $distanceValue, in: 10...10000, step: 10)
                            
                            Picker("Unit", selection: $distanceUnit) {
                                Text("meters").tag(UnitLength.meters)
                                Text("kilometers").tag(UnitLength.kilometers)
                                Text("miles").tag(UnitLength.miles)
                            }
                            .pickerStyle(.menu)
                        }
                    }
                }
                
                Section("Target Muscles") {
                    ForEach(movement.targetMuscles, id: \.self) { muscle in
                        HStack {
                            Image(systemName: "figure.arms.open")
                                .foregroundColor(.accentColor)
                            Text(muscle.rawValue)
                        }
                    }
                }
                
                Section("Target Fitness Metrics") {
                    ForEach(movement.targetMetrics, id: \.self) { metric in
                        HStack {
                            Image(systemName: "target")
                                .foregroundColor(.accentColor)
                            Text(metric.rawValue)
                        }
                    }
                }
            }
            .navigationTitle("New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Save") {
                            let goal: WorkoutGoal
                            switch goalType {
                            case .open:
                                goal = .open
                            case .time:
                                goal = .time(timeValue, .seconds)
                            case .distance:
                                goal = .distance(distanceValue, distanceUnit)
                            }
                            
                            let exercise = Exercise(movement: movement, goal: goal)
                            onSave(exercise)
                            dismiss()
                        }
                    }
                }
            }
            .alert("Exercise Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("An Exercise is a specific movement or activity that targets particular muscle groups and fitness metrics.\n\nMovements are the physical actions you perform - each automatically targets specific muscles and develops particular fitness qualities.\n\nGoal Types determine how the exercise is measured:\n• Open: No specific target - go until you're done\n• Time: Perform for a set duration (e.g., 60 seconds)\n• Distance: Cover a specific distance (e.g., 1000 meters)\n\nTarget Muscles and Fitness Metrics are automatically determined by the movement you select.")
            }
        }
    }
}

#Preview {
    CreateTrainingSessionView(workoutManager: WorkoutManager.shared)
} 
