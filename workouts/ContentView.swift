import SwiftUI
import WorkoutKit
import HealthKit

struct ContentView: View {

    @State private var selectedWorkout: CustomWorkout?
    @State private var workouts: [CustomWorkout] = []
    
    var body: some View {
        TabView {
            HomeView()
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }

            NavigationView {
                VStack {
                    List {
                        ForEach(workouts) { workout in
                            Button(action: {
                                selectedWorkout = workout
                            }) {
                                Text(workout.displayName!)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .sheet(item: $selectedWorkout) { workout in
                    WorkoutPreviewView(workout: workout)
                }
                .navigationTitle("Workouts")
            }
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }
            
            ScheduledWorkoutsView()
            .tabItem {
                Label("Scheduled", systemImage: "clock")
            }
            
            // Third tab - Settings
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }

        }
        .task {
            await requestHealthKitAuthorization()
            if workouts.count == 0 {
                await createWorkouts()
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

    private func createWorkouts() async {
        await createUpperBodyStrengthWorkout()
        await createCardioWorkout()
        await createLowerBodyStrengthWorkout()
    }

    private func createCardioWorkout() async {
        // Warmup
        let warmupStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Cycling")

        // Squats
        let runningStep = WorkoutStep(goal: .time(1500, .seconds), alert: .speed(7.5, unit: .milesPerHour), displayName: "Running")
        let runningInterval = IntervalStep(.work, step: runningStep)
        let runningBlock = IntervalBlock(steps: [runningInterval], iterations: 1)

        // Cooldown
        let cooldownStep = WorkoutStep(goal: .time(600, .seconds), displayName: "Cooldown")

        let cardioWorkout = CustomWorkout(
            activity: .running,
            location: .indoor,
            displayName: "Cardio",
            warmup: warmupStep,
            blocks: [runningBlock],
            cooldown: cooldownStep
        )

        self.workouts.append(cardioWorkout)
    }

    private func createLowerBodyStrengthWorkout() async {
        // Warmup
        let warmupStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Cycling")

        // Squats
        let squatsStep = WorkoutStep(goal: .open, displayName: "Barbell Back Squats")
        let squatsInterval = IntervalStep(.work, step: squatsStep)
        let squatsBlock = IntervalBlock(steps: [squatsInterval], iterations: 3)

        // Deadlifts
        let deadliftsStep = WorkoutStep(goal: .open, displayName: "Barbell Deadlifts")
        let deadliftsInterval = IntervalStep(.work, step: deadliftsStep)
        let deadliftsBlock = IntervalBlock(steps: [deadliftsInterval], iterations: 3)

        // Calf Raises
        let calfRaisesStep = WorkoutStep(goal: .open, displayName: "Single-Leg Calf Raises")
        let calfRaisesInterval = IntervalStep(.work, step: calfRaisesStep)
        let calfRaisesBlock = IntervalBlock(steps: [calfRaisesInterval], iterations: 3)

        // L-Sit Hold
        let lSitHoldStep = WorkoutStep(goal: .time(30, .seconds), displayName: "L-Sit Hold")
        let lSitHoldRestStep = WorkoutStep(goal: .time(30, .seconds), displayName: "Rest")
        let lSitHoldInterval = IntervalStep(.work, step: lSitHoldStep)
        let lSitHoldRecoveryInterval = IntervalStep(.recovery, step: lSitHoldRestStep)
        let lSitHoldBlock = IntervalBlock(steps: [lSitHoldInterval, lSitHoldRecoveryInterval], iterations: 3)

        // Hanging Leg Raises       
        let hangingLegRaisesStep = WorkoutStep(goal: .open, displayName: "Hanging Leg Raises")
        let hangingLegRaisesInterval = IntervalStep(.work, step: hangingLegRaisesStep)
        let hangingLegRaisesBlock = IntervalBlock(steps: [hangingLegRaisesInterval], iterations: 3)

        // Cooldown
        let cooldownStep = WorkoutStep(goal: .time(600, .seconds), displayName: "Cooldown")

        let lowerBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Lower Body Strength",
            warmup: warmupStep,
            blocks: [squatsBlock, deadliftsBlock, calfRaisesBlock, lSitHoldBlock, hangingLegRaisesBlock],
            cooldown: cooldownStep
        )

        self.workouts.append(lowerBodyStrengthWorkout)
    }
    
    private func createUpperBodyStrengthWorkout() async {

        // Warmup
        let warmupStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Warmup")

        // Calisthenics
        let pullUpsStep = WorkoutStep(goal: .open, displayName: "Pull Ups")
        let pullUpsInterval = IntervalStep(.work, step: pullUpsStep)
        let dipsStep = WorkoutStep(goal: .open, displayName: "Dips")
        let dipsInterval = IntervalStep(.work, step: dipsStep)
        let calisthenicsBlock = IntervalBlock(steps: [pullUpsInterval, dipsInterval], iterations: 2)
        
        // Lat Pulldown
        let latPulldownStep = WorkoutStep(goal: .open, displayName: "Lat Pulldown")
        let latPullDownInterval = IntervalStep(.work, step: latPulldownStep)
        let latPulldownBlock = IntervalBlock(steps: [latPullDownInterval], iterations: 3)

        // Bench Press
        let benchPressStep = WorkoutStep(goal: .open, displayName: "Bench Press") 
        let benchPressInterval = IntervalStep(.work, step: benchPressStep)
        let benchPressBlock = IntervalBlock(steps: [benchPressInterval], iterations: 3)

        // Pull Back
        let pullbackStep = WorkoutStep(goal: .open, displayName: "Pull Back")
        let pullbackInterval = IntervalStep(.work, step: pullbackStep)
        let pullbackBlock = IntervalBlock(steps: [pullbackInterval], iterations: 3)

        // Chest Flys
        let chestFlyStep = WorkoutStep(goal: .open, displayName: "Chest Flys")
        let chestFlyInterval = IntervalStep(.work, step: chestFlyStep)
        let chestFlyBlock = IntervalBlock(steps: [chestFlyInterval], iterations: 3)

        // Cooldown
        let cooldownStep = WorkoutStep(goal: .time(600, .seconds), displayName: "Cooldown")
        
        // Create Upper Body Strength Workout
        let upperBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Upper Body Strength",
            warmup: warmupStep,
            blocks: [calisthenicsBlock, latPulldownBlock, benchPressBlock, pullbackBlock, chestFlyBlock],
            cooldown: cooldownStep
        )
        
        self.workouts.append(upperBodyStrengthWorkout)

    }
}

// Extension to make CustomWorkout conform to Identifiable
extension CustomWorkout: @retroactive Identifiable {
    public var id: String {
        return UUID().uuidString
    }
}

#Preview {
    ContentView()
}
