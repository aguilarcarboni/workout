import SwiftUI
import WorkoutKit
import HealthKit

// MARK: - Create Activity Session View

struct CreateActivitySessionView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ActivitySession) -> Void
    
    @State private var sequenceName = ""
    @State private var activityGroups: [ActivityGroup] = []
    @State private var showingActivityGroupCreator = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Session Details") {
                    TextField("Session Name", text: $sequenceName)
                        .textInputAutocapitalization(.words)
                }
                
                Section("Activity Groups") {
                    ForEach(activityGroups.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                HStack {
                                    Image(systemName: activityGroups[index].activity.icon)
                                        .foregroundColor(.accentColor)
                                    Text(activityGroups[index].displayName ?? activityGroups[index].activity.displayName)
                                        .font(.headline)
                                }
                                
                                HStack {
                                    Text("\(activityGroups[index].workouts.count) workouts")
                                    Text("• \(activityGroups[index].location.displayName)")
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                // Show target metrics preview
                                if !activityGroups[index].targetMetrics.isEmpty {
                                    Text(activityGroups[index].targetMetrics.prefix(2).map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
                            }
                            Spacer()
                            Button("Delete", role: .destructive) {
                                activityGroups.remove(at: index)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Button("Add Activity Group") {
                        showingActivityGroupCreator = true
                    }
                }
                
                // Show combined target info if activity groups exist
                if !activityGroups.isEmpty {
                    let allTargetMetrics = Array(Set(activityGroups.flatMap { $0.targetMetrics }))
                    let allTargetMuscles = Array(Set(activityGroups.flatMap { $0.targetMuscles }))
                    
                    Section("Session Overview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Activity Groups: \(activityGroups.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text("Total Workouts: \(activityGroups.reduce(0) { $0 + $1.workouts.count })")
                                .font(.caption)
                                .fontWeight(.semibold)
                        }
                        
                        if !allTargetMetrics.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Fitness Metrics:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !allTargetMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Muscles:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Activity Session")
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
                            let displayName = sequenceName.isEmpty ? "Custom Session" : sequenceName
                            let session = ActivitySession(
                                activityGroups: activityGroups,
                                displayName: displayName
                            )
                            onSave(session)
                            dismiss()
                        }
                        .disabled(activityGroups.isEmpty)
                    }
                }
            }
            .alert("Activity Session Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("An Activity Session is a complete workout session that groups related workouts together. It can include warmup, main training, and cooldown workouts all in one session.\n\nActivity Types determine how the workout is tracked:\n• Strength Training: Weight lifting, resistance exercises\n• Cycling: Bike workouts, stationary or outdoor\n• Running: Cardio running activities\n• Core Training: Focused abdominal and core work\n• HIIT: High-intensity interval training\n• Flexibility: Stretching and mobility work\n• Other: General fitness activities\n\nLocation determines GPS tracking - use Indoor for gym workouts, Outdoor for running/cycling outside.")
            }
            .sheet(isPresented: $showingActivityGroupCreator) {
                CreateActivityGroupView { activityGroup in
                    activityGroups.append(activityGroup)
                }
            }
        }
    }
}

// MARK: - Create Activity Group View

struct CreateActivityGroupView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ActivityGroup) -> Void
    
    @State private var groupName = ""
    @State private var activity: HKWorkoutActivityType = .traditionalStrengthTraining
    @State private var location: HKWorkoutSessionLocationType = .indoor
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutCreator = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Group Details") {
                    TextField("Group Name (Optional)", text: $groupName)
                        .textInputAutocapitalization(.words)
                    
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
                        Text("Flexibility").tag(HKWorkoutActivityType.flexibility)
                        Text("Other").tag(HKWorkoutActivityType.other)
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
                                if let workoutType = workouts[index].workoutType {
                                    Text(workoutType.rawValue)
                                        .font(.headline)
                                } else {
                                    Text("Workout \(index + 1)")
                                        .font(.headline)
                                }
                                HStack {
                                    Text("\(workouts[index].exercises.count) exercises")
                                    if workouts[index].iterations > 1 {
                                        Text("• \(workouts[index].iterations) sets")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(.secondary)
                                
                                // Show target metrics preview
                                if !workouts[index].targetMetrics.isEmpty {
                                    Text(workouts[index].targetMetrics.prefix(2).map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(.accentColor)
                                }
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
                
                // Show combined target info if workouts exist
                if !workouts.isEmpty {
                    let allTargetMetrics = Array(Set(workouts.flatMap { $0.targetMetrics }))
                    let allTargetMuscles = Array(Set(workouts.flatMap { $0.targetMuscles }))
                    
                    Section("Group Overview") {
                        if !allTargetMetrics.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Fitness Metrics:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !allTargetMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Muscles:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Activity Group")
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
                            let displayName = groupName.isEmpty ? nil : groupName
                            let activityGroup = ActivityGroup(
                                activity: activity,
                                location: location,
                                workouts: workouts,
                                displayName: displayName
                            )
                            onSave(activityGroup)
                            dismiss()
                        }
                        .disabled(workouts.isEmpty)
                    }
                }
            }
            .alert("Activity Group Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("An Activity Group contains workouts that share the same activity type and location. This allows you to create activity sessions with multiple different workout types.\n\nFor example, a cardio session could have separate cycling and running activity groups, each tracked differently on your Apple Watch.\n\nEach activity group will be scheduled as a separate workout when you schedule the session.")
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
    @State private var workoutType: WorkoutType? = nil
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
                    Picker("Workout Type (Optional)", selection: $workoutType) {
                        Text("None").tag(nil as WorkoutType?)
                        ForEach(WorkoutType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type as WorkoutType?)
                        }
                    }
                    
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
                                
                                // Show target muscles and metrics
                                HStack {
                                    if !exercises[index].targetMuscles.isEmpty {
                                        Text("Muscles: \(exercises[index].targetMuscles.prefix(2).map { $0.rawValue }.joined(separator: ", "))")
                                            .font(.caption2)
                                            .foregroundColor(.blue)
                                    }
                                }
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
                
                // Show workout overview if exercises exist
                if !exercises.isEmpty {
                    let allTargetMetrics = Array(Set(exercises.flatMap { $0.targetMetrics }))
                    let allTargetMuscles = Array(Set(exercises.flatMap { $0.targetMuscles }))
                    
                    Section("Workout Overview") {
                        if !allTargetMetrics.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Fitness Metrics:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        if !allTargetMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Muscles:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
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
                                workoutType: workoutType
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
                Text("A Workout is a group of exercises performed together with optional rest periods between them.\n\nWorkout Types help categorize your training:\n• Warmup: Preparation exercises\n• Strength Workout: Resistance training\n• Endurance Workout: Cardio training\n• Stability Workout: Balance and core work\n• Cooldown: Recovery exercises\n\nSets determine how many times you'll repeat the entire workout. The fitness goals and muscle targets are automatically determined by the exercises you include.")
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
                            Image(systemName: iconForFitnessMetric(metric))
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
}

#Preview {
    CreateActivitySessionView { _ in }
} 
