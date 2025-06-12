import SwiftUI
import WorkoutKit

struct WorkoutsView: View {

    @State private var selectedTrainingSession: TrainingSession?
    @State var workoutManager: WorkoutManager = .shared
    
    var body: some View {
        NavigationView {
            Group {
                if workoutManager.trainingSessions.isEmpty {
                    ContentUnavailableView(
                        "No Training Sessions",
                        systemImage: "figure.run",
                        description: Text("Create a training session to see it here")
                    )
                } else {
                    VStack {
                        List {
                            ForEach(workoutManager.trainingSessions, id: \.displayName) { session in
                                TrainingSessionRow(session: session) {
                                    selectedTrainingSession = session
                                }
                            }
                        }
                    }
                    .sheet(item: $selectedTrainingSession) { session in
                        TrainingSessionDetailView(trainingSession: session)
                    }
                }
            }
            .navigationTitle("Training Sessions")
        }
        .onAppear {
            Task {
                await workoutManager.createWorkouts()
            }
        }
    }
}

struct TrainingSessionRow: View {
    let session: TrainingSession
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.displayName)
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Text("\(session.workoutSequences.count) sequence\(session.workoutSequences.count == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                if session.warmup != nil || session.cooldown != nil {
                    HStack {
                        if session.warmup != nil {
                            Label("Warmup", systemImage: "figure.walk")
                                .font(.caption2)
                                .foregroundColor(.orange)
                        }
                        if session.cooldown != nil {
                            Label("Cooldown", systemImage: "figure.cooldown")
                                .font(.caption2)
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
