import SwiftUI
import WorkoutKit
import HealthKit

struct ActivitySessionDetailView: View {
    
    let activitySession: ActivitySession

    @State private var expandedWorkouts: Set<String> = []
    @Environment(\.dismiss) private var dismiss
    
    private func scheduleActivitySession() async {
        await WorkoutManager.shared.scheduleActivitySession(activitySession)
        dismiss()
    }
    
    var body: some View {
        NavigationStack {
            VStack {
                headerSection

                List {
                    // Group workouts by activity groups
                    ForEach(Array(activitySession.activityGroups.enumerated()), id: \.offset) { groupIndex, group in
                        Section {
                            ForEach(Array(group.workouts.enumerated()), id: \.offset) { workoutIndex, workout in
                                workoutRow(for: workout, index: workoutIndex, groupIndex: groupIndex)
                            }
                        } header: {
                            HStack {
                                Image(systemName: group.activity.icon)
                                    .font(.caption)
                                    .foregroundStyle(Color("AccentColor"))
                                Text(group.activity.displayName)
                                    .font(.caption)
                                    .fontWeight(.semibold)
                                
                                Spacer()
                                
                                Text("(\(group.workouts.count) workout\(group.workouts.count == 1 ? "" : "s"))")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .navigationTitle("")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            Button {
                                Task {
                                    await scheduleActivitySession()
                                }
                            } label: {
                                Image(systemName: "applewatch")
                            }
                            .buttonStyle(.borderedProminent)
                            .tint(Color("AccentColor"))
                            .foregroundStyle(.black)
                        }
                    }
                }
            }
        }
    }
        
    private var headerSection: some View {
        Section {
            VStack(alignment: .center, spacing: 12) {
                Text(activitySession.displayName)
                    .font(.largeTitle)
                    .fontWeight(.bold)

                Text("ACTIVITY SESSION")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(.secondary)
            }
        }
    }
    
    private func workoutRow(for workout: Workout, index: Int, groupIndex: Int) -> some View {
        let intervalBlock = workout.toWorkoutKitType()
        let workoutId = "workout-\(groupIndex)-\(index)"
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
                            // Show iterations
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
                                    Text(workout.targetMetrics.map { $0.rawValue }.joined(separator: ", "))
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .lineLimit(1)
                                }
                            }
                        }
                        
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
                    let exercise = workout.exerciseForStepIndex(stepIndex)
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
                            Text("\(exercise.targetMuscles.map { $0.rawValue }.joined(separator: ", "))")
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
                            Text("\(exercise.targetMetrics.map { $0.rawValue }.joined(separator: ", "))")
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
                Text(step.step.goal.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if let alert = step.step.alert {
                Text(alert.description)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(isRest ? Color.black.opacity(0.05) : Color.black.opacity(0.1))
        .cornerRadius(8)
    }
} 
