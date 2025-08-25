import SwiftUI
import SwiftData
import WorkoutKit

struct WorkoutSessionsView: View {

    @Environment(\.modelContext) private var modelContext
    @State var workoutManager: WorkoutManager = .shared
    @State private var selectedWorkoutSession: ActivitySession?
    @State private var showingCreateForm = false
    @State private var showingScheduledWorkouts = false
    
    var body: some View {
        NavigationStack {
            Group {
                if workoutManager.activitySessions.isEmpty {
                    ContentUnavailableView(
                        "No Workout Sessions",
                        systemImage: "figure.run",
                        description: Text("Create a workout session to see it here")
                    )
                } else {
                    VStack {
                        List {
                            ForEach(workoutManager.activitySessions, id: \.id) { session in
                                WorkoutSessionRow(session: session) {
                                    selectedWorkoutSession = session
                                }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button("Delete", role: .destructive) {
                                        workoutManager.deleteActivitySession(session, from: modelContext)
                                    }
                                }
                            }
                        }
                    }
                    .sheet(item: $selectedWorkoutSession) { session in
                        ActivitySessionDetailView(activitySession: session)
                    }
                    .sheet(isPresented: $showingCreateForm) {
                        CreateWorkoutSessionView { session in
                            // Refresh workouts after adding new session
                            workoutManager.loadSessions(from: modelContext)
                        }
                    }
                    .sheet(isPresented: $showingScheduledWorkouts) {
                        ScheduledActivitySessionsView()
                    }
                }
            }
            .navigationTitle("Workout Sessions")
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
        .onAppear {
            // Load sessions from SwiftData when view appears
            workoutManager.loadSessions(from: modelContext)
        }
    }
}

struct WorkoutSessionRow: View {
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
                                    .foregroundStyle(Color("AccentColor"))
                                Text(session.activity.displayName)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "rectangle.3.offgrid")
                                    .font(.caption)
                                    .foregroundStyle(Color("AccentColor"))
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
                            .foregroundStyle(Color("AccentColor"))
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