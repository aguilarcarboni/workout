import SwiftUI
import SwiftData
import WorkoutKit
import HealthKit

// MARK: - Create Mind & Body Session View

struct CreateMindAndBodySessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    let onSave: ((ActivitySession) -> Void)?
    
    @State private var sequenceName = ""
    @State private var activityGroups: [ActivityGroup] = []
    @State private var showingActivityGroupCreator = false
    @State private var showingHelp = false
    
    // Mind & Body specific activity types
    private let mindBodyActivityTypes: [HKWorkoutActivityType] = [
        .yoga,
        .pilates,
        .flexibility,
        .mindAndBody
    ]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Mind & Body Session Details") {
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
                                .foregroundColor(Color("SecondaryAccentColor"))
                        }
                        
                        Button("Save") {
                            let displayName = sequenceName.isEmpty ? "Custom Mind & Body Session" : sequenceName
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
            .alert("Mind & Body Session Help", isPresented: $showingHelp) {
                Button("OK") { }
            } message: {
                Text("A Mind & Body Session is designed for yoga, pilates, meditation, and flexibility practices. It focuses on mindfulness, balance, and holistic wellness.\n\nMind & Body Types include:\n• Yoga: Various yoga flows and poses\n• Pilates: Core strengthening and body alignment\n• Flexibility: Stretching and mobility work\n• Meditation: Breathing exercises and mindfulness\n\nFor strength training and cardio, use the Workout section instead.")
            }
            .sheet(isPresented: $showingActivityGroupCreator) {
                CreateMindBodyActivityGroupView(availableActivityTypes: mindBodyActivityTypes) { activityGroup in
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
                                .foregroundColor(Color("SecondaryAccentColor"))
                            Text(activityGroups[index].activity.displayName)
                                .font(.headline)
                        }
                        HStack {
                            Text("\(activityGroups[index].workouts.count) practices")
                            Text("• \(activityGroups[index].location.displayName)")
                        }
                        .font(.caption)
                        .foregroundColor(Color("SecondaryAccentColor"))
                        if !activityGroups[index].targetMetrics.isEmpty {
                            Text(activityGroups[index].targetMetrics.prefix(2).map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(Color("SecondaryAccentColor"))
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
            .foregroundColor(Color("SecondaryAccentColor"))
        }
    }

    private var sessionOverviewSection: some View {
        let allTargetMetrics = Array(Set(activityGroups.flatMap { $0.targetMetrics }))
        let allTargetMuscles = Array(Set(activityGroups.flatMap { $0.targetMuscles }))
        return Group {
            if !activityGroups.isEmpty {
                Section("Session Overview") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Total Activity Groups: \(activityGroups.count)")
                            .font(.caption)
                            .fontWeight(.semibold)
                        Text("Total Practices: \(activityGroups.reduce(0) { $0 + $1.workouts.count })")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    if !allTargetMetrics.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Focus Areas:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(allTargetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(Color("SecondaryAccentColor"))
                        }
                    }
                    if !allTargetMuscles.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Target Areas:")
                                .font(.caption)
                                .fontWeight(.semibold)
                            Text(allTargetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                .font(.caption2)
                                .foregroundColor(Color("SecondaryAccentColor"))
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Create Mind & Body Activity Group View

struct CreateMindBodyActivityGroupView: View {
    @Environment(\.dismiss) private var dismiss
    let availableActivityTypes: [HKWorkoutActivityType]
    let onSave: (ActivityGroup) -> Void
    
    @State private var activity: HKWorkoutActivityType = .yoga
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
                
                Section("Practices") {
                    ForEach(workouts.indices, id: \.self) { index in
                        HStack {
                            VStack(alignment: .leading) {
                                Text("Practice \(index + 1)")
                                    .font(.headline)
                                HStack {
                                    Text("\(workouts[index].exercises.count) movements")
                                    if workouts[index].iterations > 1 {
                                        Text("• \(workouts[index].iterations) rounds")
                                    }
                                }
                                .font(.caption)
                                .foregroundColor(Color("SecondaryAccentColor"))
                                
                                // Show target metrics preview
                                if !workouts[index].targetMetrics.isEmpty {
                                    Text(workouts[index].targetMetrics.prefix(2).map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundColor(Color("SecondaryAccentColor"))
                                }
                            }
                            Spacer()
                            Button("Delete", role: .destructive) {
                                workouts.remove(at: index)
                            }
                            .font(.caption)
                        }
                    }
                    
                    Button("Add Practice") {
                        showingWorkoutCreator = true
                    }
                    .foregroundColor(Color("SecondaryAccentColor"))
                }
                
                // Show combined target info if workouts exist
                if !workouts.isEmpty {
                    let allTargetMetrics = Array(Set(workouts.flatMap { $0.targetMetrics }))
                    let allTargetMuscles = Array(Set(workouts.flatMap { $0.targetMuscles }))
                    
                    Section("Group Overview") {
                        if !allTargetMetrics.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Focus Areas:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(Color("SecondaryAccentColor"))
                            }
                        }
                        
                        if !allTargetMuscles.isEmpty {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Target Areas:")
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                Text(allTargetMuscles.map { $0.rawValue }.joined(separator: ", "))
                                    .font(.caption2)
                                    .foregroundColor(Color("SecondaryAccentColor"))
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
                                .foregroundColor(Color("SecondaryAccentColor"))
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
                Text("An Activity Group contains practices focused on mind & body wellness. This ensures your session stays focused on yoga, pilates, meditation, and flexibility movements.\n\nEach activity group will be scheduled as a separate practice when you schedule the session to your Apple Watch.")
            }
            .sheet(isPresented: $showingWorkoutCreator) {
                CreateWorkoutView(title: "New Practice", isWorkoutSession: false) { workout in
                    workouts.append(workout)
                }
            }
        }
    }
}

#Preview {
    CreateMindAndBodySessionView(onSave: nil)
        .modelContainer(for: [
            PersistentActivitySession.self,
            PersistentActivityGroup.self,
            PersistentWorkout.self,
            PersistentExercise.self,
            PersistentRest.self
        ], inMemory: true)
} 