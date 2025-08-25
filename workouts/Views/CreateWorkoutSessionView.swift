import SwiftUI
import SwiftData
import WorkoutKit
import HealthKit

// MARK: - Create Workout Session View

struct CreateWorkoutSessionView: View {
    let onSave: ((ActivitySession) -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var sequenceName = ""
    @State private var activityGroups: [ActivityGroup] = []
    @State private var showingActivityGroupCreator = false
    @State private var showingHelp = false
    
    // Workout-specific activity types
    private let workoutActivityTypes: [HKWorkoutActivityType] = [
        .traditionalStrengthTraining,
        .functionalStrengthTraining,
        .crossTraining,
        .mixedCardio,
        .highIntensityIntervalTraining,
        .jumpRope,
        .cycling,
        .running,
        .coreTraining,
        .other
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Workout Session Details") {
                    TextField("Session Name", text: $sequenceName)
                        .textInputAutocapitalization(.words)
                }
                
                activityGroupsSection
                
                sessionOverviewSection
            }
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Save") {
                            let displayName = sequenceName.isEmpty ? "Custom Workout" : sequenceName
                            let session = ActivitySession(
                                activityGroups: activityGroups,
                                displayName: displayName
                            )
                            
                            // Save to SwiftData
                            WorkoutManager.shared.addActivitySession(session, to: modelContext)
                            
                            // Call optional callback
                            onSave?(session)
                            dismiss()
                        }
                        .disabled(activityGroups.isEmpty)
                    }
                }
            }
            .alert("Workout Session Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("A Workout Session is designed for strength training, cardio, and fitness exercises. It groups related workouts together for comprehensive training.\n\nWorkout Types include:\n• Strength Training: Weight lifting, resistance exercises\n• Cardio: Running, cycling, HIIT\n• Functional Training: Movement-based exercises\n• Cross Training: Mixed fitness activities\n\nFor yoga, pilates, and meditation, use the Mind & Body section instead.")
            }
            .sheet(isPresented: $showingActivityGroupCreator) {
                CreateWorkoutActivityGroupView(availableActivityTypes: workoutActivityTypes) { activityGroup in
                    activityGroups.append(activityGroup)
                }
            }
        }
    }
    
    private var activityGroupsSection: some View {
        Section("Activity Groups") {
            ForEach(activityGroups.indices, id: \.self) { index in
                HStack {
                    VStack(alignment: .leading) {
                        HStack {
                            Image(systemName: activityGroups[index].activity.icon)
                                .foregroundColor(.accentColor)
                            Text(activityGroups[index].activity.displayName)
                                .font(.headline)
                        }
                        HStack {
                            Text("\(activityGroups[index].workouts.count) workouts")
                            Text("• \(activityGroups[index].location.displayName)")
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
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
            .foregroundColor(.accentColor)
        }
    }

    private var sessionOverviewSection: some View {
        let allTargetMetrics = Array(Set(activityGroups.flatMap { $0.targetMetrics }))
        let allTargetMuscles = Array(Set(activityGroups.flatMap { $0.targetMuscles }))
        let totalWorkouts = activityGroups.reduce(0) { $0 + $1.workouts.count }
        
        return Group {
            if !activityGroups.isEmpty {
                Section("Session Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Activity Groups: \(activityGroups.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Total Workouts: \(totalWorkouts)")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    
                    if !allTargetMetrics.isEmpty {
                        metricsSection(allTargetMetrics)
                    }
                    
                    if !allTargetMuscles.isEmpty {
                        musclesSection(allTargetMuscles)
                    }
                }
            }
        }
    }
    
    private func metricsSection(_ metrics: [FitnessMetric]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Target Fitness Metrics:")
                .font(.caption)
                .fontWeight(.semibold)
            Text(metrics.map { $0.rawValue }.joined(separator: ", "))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
    
    private func musclesSection(_ muscles: [Muscle]) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Target Muscles:")
                .font(.caption)
                .fontWeight(.semibold)
            Text(muscles.map { $0.rawValue }.joined(separator: ", "))
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }
}

// MARK: - Create Workout Activity Group View

struct CreateWorkoutActivityGroupView: View {
    @Environment(\.dismiss) private var dismiss
    let availableActivityTypes: [HKWorkoutActivityType]
    let onSave: (ActivityGroup) -> Void
    
    @State private var activity: HKWorkoutActivityType = .traditionalStrengthTraining
    @State private var location: HKWorkoutSessionLocationType = .indoor
    @State private var workouts: [Workout] = []
    @State private var showingWorkoutCreator = false
    @State private var showingHelp = false
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Activity Group Details") {
                    Picker("Activity Type", selection: $activity) {
                        ForEach(availableActivityTypes, id: \.self) { activityType in
                            Text(activityType.displayName).tag(activityType)
                        }
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
                    .foregroundColor(.accentColor)
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
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(.accentColor)
                        }
                        
                        Button("Save") {
                            let activityGroup = ActivityGroup(
                                activity: activity,
                                location: location,
                                workouts: workouts
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
                Text("An Activity Group contains workouts focused on fitness and strength training. This ensures your workout session stays focused on exercises like strength training, cardio, and functional movements.\n\nEach activity group will be scheduled as a separate workout when you schedule the session to your Apple Watch.")
            }
            .sheet(isPresented: $showingWorkoutCreator) {
                CreateWorkoutView(title: "New Workout", isWorkoutSession: true) { workout in
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
    let isWorkoutSession: Bool
    let onSave: (Workout) -> Void
    
    @State private var iterations = 1
    @State private var exercises: [Exercise] = []
    @State private var showingExerciseCreator = false
    @State private var showingHelp = false
    
    init(title: String = "New Workout", isWorkoutSession: Bool = true, onSave: @escaping (Workout) -> Void) {
        self.title = title
        self.isWorkoutSession = isWorkoutSession
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
                        exerciseRow(at: index)
                    }
                    
                    Button("Add Exercise") {
                        showingExerciseCreator = true
                    }
                    .foregroundColor(isWorkoutSession ? .accentColor : Color("SecondaryAccentColor"))
                }
                
                if !exercises.isEmpty {
                    overviewSection
                }
            }
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(isWorkoutSession ? .accentColor : Color("SecondaryAccentColor"))
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
                Text("A Workout is a group of exercises performed together with optional rest periods between them.\n\nSets determine how many times you'll repeat the entire workout. The fitness goals and muscle targets are automatically determined by the exercises you include.")
            }
            .sheet(isPresented: $showingExerciseCreator) {
                CreateExerciseView(isWorkoutSession: isWorkoutSession) { exercise in
                    exercises.append(exercise)
                }
            }
        }
    }
    
    private func exerciseRow(at index: Int) -> some View {
        HStack {
            VStack(alignment: .leading) {
                Text(exercises[index].movement.rawValue)
                    .font(.headline)
                Text(exercises[index].goal.description)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // Show target muscles and metrics
                if !exercises[index].targetMuscles.isEmpty {
                    Text("Muscles: \(exercises[index].targetMuscles.prefix(2).map { $0.rawValue }.joined(separator: ", "))")
                        .font(.caption2)
                        .foregroundColor(.blue)
                }
            }
            Spacer()
            Button("Delete", role: .destructive) {
                exercises.remove(at: index)
            }
            .font(.caption)
        }
    }
    
    private var overviewSection: some View {
        let allTargetMetrics = Array(Set(exercises.flatMap { $0.targetMetrics }))
        let allTargetMuscles = Array(Set(exercises.flatMap { $0.targetMuscles }))
        
        return Section("Workout Overview") {
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

// MARK: - Create Exercise View

struct CreateExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let isWorkoutSession: Bool
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
    
    // Filter movements based on session type
    private var availableMovements: [Movement] {
        if isWorkoutSession {
            // Workout movements (strength, cardio, functional)
            return [
                // Upper body movements
                .pullUps, .chinUps, .chestDips, .tricepDips, .benchPress, .latPulldowns,
                .cablePullover, .chestFlys, .bicepCurls, .hammerCurls, .preacherCurls,
                .lateralRaises, .overheadPress, .facePulls, .tricepPulldown, .overheadPull,
                
                // Lower body movements
                .barbellBackSquat, .barbellDeadlifts, .calfRaises, .adductors, .abductors,
                
                // Core movements
                .lSit, .legRaise,
                
                // Cardio movements
                .cycling, .run, .sprint, .jumpRope,
                
                // Complex movements
                .bearCrawls, .hingeToSquat, .pikePulse, .precisionBroadJump, .ropeClimbing
            ]
        } else {
            // Mind & body movements (yoga, pilates, stretching, meditation)
            return [
                // Stretching movements
                .benchHipFlexorStretch, .hamstringStretch, .quadricepsStretch, .calfStretch,
                .shoulderStretch, .neckStretch, .spinalTwist, .childsPose,
                
                // Yoga movements
                .downwardDog, .warriorOne, .warriorTwo, .trianglePose, .treePose,
                .catCowPose, .cobralPose, .planktoPose, .mountainPose, .sunSalutation,
                
                // Pilates movements
                .pilatesHundred, .pilatesRollUp, .pilatesSingleLegCircle, .pilatesTeaser,
                .pilatesPlank, .pilatesBridge,
                
                // Mindfulness movements
                .meditation, .breathingExercise, .bodyScanning, .progressiveMuscleRelaxation
            ]
        }
    }
    
    init(isWorkoutSession: Bool = true, onSave: @escaping (Exercise) -> Void) {
        self.isWorkoutSession = isWorkoutSession
        self.onSave = onSave
        
        // Set initial movement based on session type
        _movement = State(initialValue: isWorkoutSession ? .pullUps : .downwardDog)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    Picker("Movement", selection: $movement) {
                        ForEach(availableMovements, id: \.self) { movement in
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
                    
                    goalInputSection
                }
                
                Section("Target Muscles") {
                    ForEach(movement.targetMuscles, id: \.self) { muscle in
                        HStack {
                            Image(systemName: "figure.arms.open")
                                .foregroundColor(isWorkoutSession ? .accentColor : Color("SecondaryAccentColor"))
                            Text(muscle.rawValue)
                        }
                    }
                }
                
                Section("Target Fitness Metrics") {
                    ForEach(movement.targetMetrics, id: \.self) { metric in
                        HStack {
                            Image(systemName: iconForFitnessMetric(metric))
                                .foregroundColor(isWorkoutSession ? .accentColor : Color("SecondaryAccentColor"))
                            Text(metric.rawValue)
                        }
                    }
                }
            }
            .toolbar {
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: { showingHelp = true }) {
                            Image(systemName: "info.circle")
                                .foregroundColor(isWorkoutSession ? .accentColor : Color("SecondaryAccentColor"))
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
            .alert(isWorkoutSession ? "Exercise Help" : "Movement Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                if isWorkoutSession {
                    Text("An Exercise is a specific movement or activity that targets particular muscle groups and fitness metrics.\n\nWorkout movements include strength training, cardio, and functional exercises. Each automatically targets specific muscles and develops particular fitness qualities.\n\nGoal Types determine how the exercise is measured:\n• Open: No specific target - go until you're done\n• Time: Perform for a set duration (e.g., 60 seconds)\n• Distance: Cover a specific distance (e.g., 1000 meters)")
                } else {
                    Text("A Movement in mind & body practice focuses on mindfulness, flexibility, and wellness.\n\nMind & Body movements include yoga poses, pilates exercises, stretching, and meditation practices. Each promotes specific wellness benefits and body awareness.\n\nGoal Types determine how the movement is measured:\n• Open: Practice at your own pace\n• Time: Hold or practice for a set duration\n• Distance: Not typically used for mind & body practices")
                }
            }
        }
    }
    
    @ViewBuilder
    private var goalInputSection: some View {
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