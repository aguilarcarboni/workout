import SwiftUI
import WorkoutKit
import HealthKit

struct MindAndBodyView: View {

    @State private var selectedMindAndBodySession: ActivitySession?
    @State private var showingCreateForm = false
    @State private var showingScheduledWorkouts = false
    @ObservedObject var mindAndBodyManager: MindAndBodyManager = .shared
    
    var body: some View {
        NavigationStack {
            Group {
                if mindAndBodyManager.mindAndBodySessions.isEmpty {
                    ContentUnavailableView(
                        "No Mind & Body Sessions",
                        systemImage: "figure.mind.and.body",
                        description: Text("Create a mind & body session to see it here")
                    )
                } else {
                    VStack {
                        List {
                            ForEach(mindAndBodyManager.mindAndBodySessions, id: \.id) { session in
                                MindAndBodySessionRow(session: session) {
                                    selectedMindAndBodySession = session
                                }
                            }
                        }
                    }
                    .sheet(item: $selectedMindAndBodySession) { session in
                        ActivitySessionDetailView(activitySession: session)
                    }
                    .sheet(isPresented: $showingCreateForm) {
                        CreateMindAndBodySessionView { session in
                            mindAndBodyManager.addMindAndBodySession(session)
                        }
                    }
                    .sheet(isPresented: $showingScheduledWorkouts) {
                        ScheduledWorkoutsView()
                    }
                }
            }
            .navigationTitle("Mind & Body")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingScheduledWorkouts = true
                    } label: {
                        Image(systemName: "calendar")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct MindAndBodySessionRow: View {
    let session: ActivitySession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(session.displayName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if session.activityGroups.count == 1 {
                            HStack(spacing: 4) {
                                Image(systemName: session.activity.icon)
                                    .font(.caption)
                                    .foregroundStyle(Color("SecondaryAccentColor"))
                                Text(session.activity.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.3.offgrid")
                                    .font(.caption)
                                    .foregroundStyle(Color("SecondaryAccentColor"))
                                Text("\(session.activityGroups.count) activity types")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("\(session.workouts.count) workout\(session.workouts.count == 1 ? "" : "s")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if session.activityGroups.count == 1 {
                            HStack(spacing: 4) {
                                Image(systemName: session.location.icon)
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(session.location.displayName)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            Text("\(session.activityGroups.count) groups")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Show target metrics if available
                if !session.targetMetrics.isEmpty {
                    HStack {
                        Image(systemName: "target")
                            .font(.caption2)
                            .foregroundStyle(Color("SecondaryAccentColor"))
                        Text(session.targetMetrics.prefix(3).map { $0.rawValue }.joined(separator: ", "))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                        
                        if session.targetMetrics.count > 3 {
                            Text("& \(session.targetMetrics.count - 3) more")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}

struct CreateMindAndBodySessionView: View {
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
                            VStack(alignment: .leading, spacing: 4) {
                                Text(activityGroups[index].displayName ?? activityGroups[index].activity.displayName)
                                    .font(.headline)
                                
                                Text("\(activityGroups[index].workouts.count) workout\(activityGroups[index].workouts.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                HStack {
                                    Image(systemName: activityGroups[index].activity.icon)
                                        .font(.caption2)
                                        .foregroundStyle(Color("SecondaryAccentColor"))
                                    Text(activityGroups[index].activity.displayName)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }
                            }
                            
                            Spacer()
                            
                            Button("Delete", role: .destructive) {
                                activityGroups.remove(at: index)
                            }
                            .font(.caption)
                        }
                        .padding(.vertical, 4)
                    }
                    
                    Button("Add Activity Group") {
                        showingActivityGroupCreator = true
                    }
                    .foregroundColor(.accentColor)
                }
                
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
            .navigationTitle("New Mind & Body Session")
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
                            let displayName = sequenceName.isEmpty ? "Custom Mind & Body Session" : sequenceName
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
            .alert("Mind & Body Session Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("A Mind & Body Session focuses on activities that enhance flexibility, balance, mindfulness, and overall wellness. It can include yoga, pilates, stretching, and meditation practices.\n\nActivity Types:\n• Yoga: Traditional poses and flows\n• Pilates: Core strengthening and stability\n• Flexibility: Stretching and mobility work\n• Mind and Body: Meditation and breathing exercises\n• Preparation and Recovery: Gentle movement and relaxation\n\nLocation determines GPS tracking - typically Indoor for most mind & body practices.")
            }
            .sheet(isPresented: $showingActivityGroupCreator) {
                CreateMindAndBodyActivityGroupView { activityGroup in
                    activityGroups.append(activityGroup)
                }
            }
        }
    }
}

struct CreateMindAndBodyActivityGroupView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (ActivityGroup) -> Void
    
    @State private var groupName = ""
    @State private var activity: HKWorkoutActivityType = .yoga
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
                        Text("Yoga").tag(HKWorkoutActivityType.yoga)
                        Text("Pilates").tag(HKWorkoutActivityType.pilates)
                        Text("Flexibility").tag(HKWorkoutActivityType.flexibility)
                        Text("Mind and Body").tag(HKWorkoutActivityType.mindAndBody)
                        Text("Preparation and Recovery").tag(HKWorkoutActivityType.preparationAndRecovery)
                        Text("Barre").tag(HKWorkoutActivityType.barre)
                        Text("Tai Chi").tag(HKWorkoutActivityType.taiChi)
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
                                Text(workouts[index].workoutType?.rawValue ?? "Workout")
                                    .font(.headline)
                                Text("\(workouts[index].exercises.count) exercise\(workouts[index].exercises.count == 1 ? "" : "s")")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                
                                if workouts[index].iterations > 1 {
                                    Text("Sets: \(workouts[index].iterations)")
                                        .font(.caption)
                                        .foregroundColor(.blue)
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
                
                if !workouts.isEmpty {
                    let allTargetMetrics = Array(Set(workouts.flatMap { $0.targetMetrics }))
                    let allTargetMuscles = Array(Set(workouts.flatMap { $0.targetMuscles }))
                    
                    Section("Activity Group Overview") {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Workouts: \(workouts.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            Text("Total Exercises: \(workouts.reduce(0) { $0 + $1.exercises.count })")
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
                Text("An Activity Group contains workouts that share the same activity type and location. For mind & body activities:\n\n• Yoga: Traditional poses, flows, and breathing\n• Pilates: Core strengthening and stability exercises\n• Flexibility: Stretching and mobility work\n• Mind and Body: Meditation and mindfulness practices\n• Preparation and Recovery: Gentle movement and relaxation\n\nEach workout within the group can have different exercises and structures.")
            }
            .sheet(isPresented: $showingWorkoutCreator) {
                CreateMindAndBodyWorkoutView { workout in
                    workouts.append(workout)
                }
            }
        }
    }
}

struct CreateMindAndBodyWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Workout) -> Void
    
    @State private var workoutType: WorkoutType? = nil
    @State private var iterations: Int = 1
    @State private var exercises: [Exercise] = []
    @State private var restPeriods: [Rest] = []
    @State private var showingExerciseCreator = false
    @State private var showingHelp = false
    
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
                    .foregroundColor(.accentColor)
                }
                
                Section("Rest Periods") {
                    Text("Rest periods will be automatically added between exercises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ForEach(restPeriods.indices, id: \.self) { index in
                        HStack {
                            Text("Rest \(index + 1): \(goalDescription(restPeriods[index].goal))")
                                .font(.caption)
                            Spacer()
                            Button("Delete", role: .destructive) {
                                restPeriods.remove(at: index)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Button("Add Custom Rest") {
                        restPeriods.append(Rest(goal: .time(30, .seconds)))
                    }
                    .foregroundColor(.accentColor)
                }
                
                if !exercises.isEmpty {
                    Section("Workout Overview") {
                        let allTargetMetrics = Array(Set(exercises.flatMap { $0.targetMetrics }))
                        let allTargetMuscles = Array(Set(exercises.flatMap { $0.targetMuscles }))
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Total Exercises: \(exercises.count)")
                                .font(.caption)
                                .fontWeight(.semibold)
                            
                            if iterations > 1 {
                                Text("Sets: \(iterations)")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                            }
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
            .navigationTitle("New Workout")
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
                            // Create default rest periods if none exist
                            var finalRestPeriods = restPeriods
                            if finalRestPeriods.isEmpty && exercises.count > 1 {
                                finalRestPeriods = Array(repeating: Rest(goal: .time(15, .seconds)), count: exercises.count - 1)
                            }
                            
                            let workout = Workout(
                                exercises: exercises,
                                restPeriods: finalRestPeriods,
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
                Text("A Workout is a structured sequence of exercises designed to improve specific fitness metrics. For mind & body workouts:\n\n• Focus on movements that enhance flexibility, balance, and mindfulness\n• Consider the flow between exercises\n• Use appropriate rest periods for transitions\n• Adjust sets based on the intensity and duration of each exercise\n\nWorkout Types help categorize the purpose and structure of your workout.")
            }
            .sheet(isPresented: $showingExerciseCreator) {
                CreateMindAndBodyExerciseView { exercise in
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

struct CreateMindAndBodyExerciseView: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: (Exercise) -> Void
    
    @State private var movement: Movement = .downwardDog
    @State private var goalType: GoalType = .time
    @State private var timeValue: Double = 60
    @State private var showingHelp = false
    
    enum GoalType: String, CaseIterable {
        case open = "Open"
        case time = "Time"
    }
    
    // Filter movements to show only mind & body relevant ones
    private var mindAndBodyMovements: [Movement] {
        Movement.allCases.filter { movement in
            let metrics = movement.targetMetrics
            return metrics.contains(.mobility) || metrics.contains(.stability) || 
                   movement.rawValue.contains("Yoga") || movement.rawValue.contains("Pilates") ||
                   movement.rawValue.contains("Stretch") || movement.rawValue.contains("Pose") ||
                   movement.rawValue.contains("Meditation") || movement.rawValue.contains("Breathing")
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Exercise Details") {
                    Picker("Movement", selection: $movement) {
                        ForEach(mindAndBodyMovements, id: \.self) { movement in
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
                        Stepper("Duration: \(Int(timeValue)) seconds", value: $timeValue, in: 5...1800, step: 5)
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
                            let goal: WorkoutGoal = goalType == .open ? .open : .time(timeValue, .seconds)
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
                Text("An Exercise is a specific movement or activity that targets particular muscle groups and fitness metrics. For mind & body exercises:\n\n• Focus on movements that enhance flexibility, balance, and mindfulness\n• Yoga poses help with strength, flexibility, and mental focus\n• Pilates exercises build core strength and stability\n• Stretching movements improve mobility and recovery\n• Mindfulness practices enhance mental clarity and relaxation\n\nGoal Types:\n• Open: Hold or perform until you feel ready to move on\n• Time: Hold or perform for a specific duration")
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
    MindAndBodyView()
}
