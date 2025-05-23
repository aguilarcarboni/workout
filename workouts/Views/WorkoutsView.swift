import SwiftUI
import WorkoutKit

struct WorkoutsView: View {

    @State private var selectedWorkoutSequence: WorkoutSequence?
    @State var workoutManager: WorkoutManager = .shared
    
    var body: some View {
        NavigationView {
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
            .navigationTitle("Workout Sequences")
        }
    }
}