import SwiftUI
import WorkoutKit

struct WorkoutsView: View {

    @State private var selectedWorkoutSequence: WorkoutSequence?
    @State var workoutManager: WorkoutManager = .shared
    
    var body: some View {
        NavigationView {
            Group {
                if workoutManager.workoutSequences.isEmpty {
                    ContentUnavailableView(
                        "No Workout Sequences",
                        systemImage: "figure.run",
                        description: Text("Create a workout sequence to see it here")
                    )
                } else {
                    VStack {
                        List {
                            ForEach(workoutManager.workoutSequences) { sequence in
                                Button(action: {
                                    selectedWorkoutSequence = sequence
                                }) {
                                    Text(sequence.displayName)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .sheet(item: $selectedWorkoutSequence) { sequence in
                        WorkoutPreviewView(workoutSequence: sequence)
                    }
                }
            }
            .navigationTitle("Workout Sequences")
        }
    }
}
