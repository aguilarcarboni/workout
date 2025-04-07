import SwiftUI
import WorkoutKit
import HealthKit

struct ContentView: View {

    @State private var customWorkout: CustomWorkout?
    @State private var workoutPlan: WorkoutPlan?
    @State private var selectedWorkout: CustomWorkout?
    @State private var workouts: [CustomWorkout] = []
    
    var body: some View {
        TabView {
            // First tab - Workout view
            NavigationView {
                VStack {

                    Image(systemName: "figure.strengthtraining.traditional")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 100, height: 100)
                        .foregroundColor(Color("AccentColor"))
                    
                    Text("Workouts")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        
                    Text("Schedule your workouts now")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                }
                .padding()
                .sheet(item: $selectedWorkout) { workout in
                    WorkoutView(workout: workout)
                }
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

                        
            // Second tab - New Workout
            NavigationView {
                VStack {
                    List {
                        ForEach(workouts) { workout in
                            Button(action: {
                                selectedWorkout = workout
                            }) {
                                HStack {
                                    Text(workout.displayName!)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(.gray)
                                }
                            }
                        }
                    }
                }
                .navigationTitle("All Workouts")
            }
            .tabItem {
                Label("New", systemImage: "plus")
            }
            
            // Third tab - Settings
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }

        }
        .task {
            await requestHealthKitAuthorization()
            if workoutPlan == nil {
                await createWorkout()
            }
        }
    }
    
    private func requestHealthKitAuthorization() async {
        let healthStore = HKHealthStore()
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [HKObjectType.workoutType()]
        
        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
            print("HealthKit authorization successful")
        } catch {
            print("HealthKit authorization failed: \(error)")
        }
    }
    
    private func createWorkout() async {
        let warmupStep = WorkoutStep(goal: .time(120, .seconds))
        let benchPressStep = WorkoutStep(goal: .time(60, .seconds))
        let benchPressInterval = IntervalStep(.work, step: benchPressStep)
        let benchPressBlock = IntervalBlock(steps: [benchPressInterval], iterations: 3)
        let cooldownStep = WorkoutStep(goal: .time(60, .seconds))
        
        // Create sample workouts
        let benchPressWorkout = CustomWorkout(
            activity: .functionalStrengthTraining,
            location: .indoor,
            displayName: "Bench Press Workout",
            warmup: warmupStep,
            blocks: [benchPressBlock],
            cooldown: cooldownStep
        )

        self.customWorkout = benchPressWorkout
        self.workouts = [benchPressWorkout]
        
        do {
            let workout = WorkoutPlan.Workout.custom(benchPressWorkout)
            let plan = WorkoutPlan(workout, id: UUID())
            self.workoutPlan = plan
            
            print("Workout created successfully")
        }
    }
}

// Extension to make CustomWorkout conform to Identifiable
extension CustomWorkout: Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}

#Preview {
    ContentView()
}

#Preview {
    ContentView()
}
