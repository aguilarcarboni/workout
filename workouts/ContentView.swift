import SwiftUI
import WorkoutKit
import HealthKit

struct ContentView: View {

    @State private var selectedWorkoutSequence: WorkoutSequence?
    @State private var workoutSequences: [WorkoutSequence] = []
    
    var body: some View {
        TabView {
            NavigationView {
                VStack {
                    List {
                        ForEach(workoutSequences) { sequence in
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
                .navigationTitle("Workouts")
            }
            .tabItem {
                Label("Workout", systemImage: "figure.strengthtraining.traditional")
            }
            
            ScheduledWorkoutsView()
            .tabItem {
                Label("Scheduled", systemImage: "clock")
            }
            
            SettingsView()
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .task {
            await requestHealthKitAuthorization()
            if workoutSequences.count == 0 {
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
        // Create individual workout sequences
        let upperBodySequence = await createUpperBodyStrengthWorkoutSequence()
        let lowerBodySequence = await createLowerBodyStrengthWorkoutSequence()
        let cardioSequence = await createCardioWorkoutSequence()
        
        // Add sequences to the array
        workoutSequences.append(upperBodySequence)
        workoutSequences.append(lowerBodySequence)
        workoutSequences.append(cardioSequence)
    }

    private func createUpperBodyStrengthWorkoutSequence() async -> WorkoutSequence {
        
        // Initialize Recovery Step
        // Used to let the user go to the machine and/or rest
        let recoveryStep = WorkoutStep(goal: .open, displayName: "Rest")
        let recoveryInterval = IntervalStep(.recovery, step: recoveryStep)

        // Warmup
        let warmupStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Warmup")
        let warmupInterval = IntervalStep(.work, step: warmupStep)
        let warmupBlock = IntervalBlock(steps: [warmupInterval], iterations: 1)
        let warmupWorkout = CustomWorkout(
            activity: .flexibility,
            location: .indoor,
            displayName: "Warmup",
            blocks: [warmupBlock]
        )

        // Upper Body Strength Workout
        let pullUpsStep = WorkoutStep(goal: .open, displayName: "Pull Ups")
        let pullUpsInterval = IntervalStep(.work, step: pullUpsStep)
        let dipsStep = WorkoutStep(goal: .open, displayName: "Dips")
        let dipsInterval = IntervalStep(.work, step: dipsStep)
        let calisthenicsBlock = IntervalBlock(steps: [pullUpsInterval, recoveryInterval, dipsInterval, recoveryInterval], iterations: 2)

        let latPulldownStep = WorkoutStep(goal: .open, displayName: "Lat Pulldown")
        let latPullDownInterval = IntervalStep(.work, step: latPulldownStep)
        let latPulldownBlock = IntervalBlock(steps: [latPullDownInterval, recoveryInterval], iterations: 3)

        let benchPressStep = WorkoutStep(goal: .open, displayName: "Bench Press") 
        let benchPressInterval = IntervalStep(.work, step: benchPressStep)
        let benchPressBlock = IntervalBlock(steps: [benchPressInterval, recoveryInterval], iterations: 3)

        let pullbackStep = WorkoutStep(goal: .open, displayName: "Pull Back")
        let pullbackInterval = IntervalStep(.work, step: pullbackStep)
        let pullbackBlock = IntervalBlock(steps: [pullbackInterval, recoveryInterval], iterations: 3)

        let chestFlyStep = WorkoutStep(goal: .open, displayName: "Chest Flys")
        let chestFlyInterval = IntervalStep(.work, step: chestFlyStep)
        let chestFlyBlock = IntervalBlock(steps: [chestFlyInterval, recoveryInterval], iterations: 3)
        
        let upperBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Upper Body Strength",
            blocks: [calisthenicsBlock, latPulldownBlock, benchPressBlock, pullbackBlock, chestFlyBlock],
        )
        
        // Cooldown
        let cooldownStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Cooldown")
        let cooldownInterval = IntervalStep(.work, step: cooldownStep)
        let cooldownBlock = IntervalBlock(steps: [cooldownInterval], iterations: 1)
        let cooldownWorkout = CustomWorkout(
            activity: .cooldown,
            location: .indoor,
            displayName: "Cooldown",
            blocks: [cooldownBlock]
        )
        
        return WorkoutSequence(
            workouts: [warmupWorkout, upperBodyStrengthWorkout, cooldownWorkout],
            displayName: "Upper Body Strength"
        )
    }

    private func createLowerBodyStrengthWorkoutSequence() async -> WorkoutSequence {
        // Initialize Recovery Step
        let recoveryStep = WorkoutStep(goal: .open, displayName: "Rest")
        let recoveryInterval = IntervalStep(.recovery, step: recoveryStep)

        // Warmup
        let warmupStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Warmup")
        let warmupInterval = IntervalStep(.work, step: warmupStep)
        let warmupBlock = IntervalBlock(steps: [warmupInterval], iterations: 1)
        let warmupWorkout = CustomWorkout(
            activity: .flexibility,
            location: .indoor,
            displayName: "Warmup",
            blocks: [warmupBlock]
        )

        // Cycling Warmup
        let cyclingStep = WorkoutStep(goal: .time(600, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling")
        let cyclingInterval = IntervalStep(.work, step: cyclingStep)
        let cyclingBlock = IntervalBlock(steps: [cyclingInterval, recoveryInterval], iterations: 1)
        let cyclingWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cycling",
            blocks: [cyclingBlock]
        )

        // Lower Body Strength Workout
        let squatsStep = WorkoutStep(goal: .open, displayName: "Barbell Back Squats")
        let squatsInterval = IntervalStep(.work, step: squatsStep)
        let squatsBlock = IntervalBlock(steps: [squatsInterval, recoveryInterval], iterations: 2)

        let deadliftsStep = WorkoutStep(goal: .open, displayName: "Barbell Deadlifts")
        let deadliftsInterval = IntervalStep(.work, step: deadliftsStep)
        let deadliftsBlock = IntervalBlock(steps: [deadliftsInterval, recoveryInterval], iterations: 2)

        let calfRaisesStep = WorkoutStep(goal: .open, displayName: "Single-Leg Calf Raises")
        let calfRaisesInterval = IntervalStep(.work, step: calfRaisesStep)
        let calfRaisesBlock = IntervalBlock(steps: [calfRaisesInterval,recoveryInterval], iterations: 2)

        let lowerBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Lower Body Strength",
            blocks: [squatsBlock, deadliftsBlock, calfRaisesBlock],
        )
        
        // Core Workout
        let lSitHoldStep = WorkoutStep(goal: .time(30, .seconds), displayName: "L-Sit Hold")
        let lSitHoldInterval = IntervalStep(.work, step: lSitHoldStep)
        
        let hangingLegRaisesStep = WorkoutStep(goal: .open, displayName: "Hanging Leg Raises")
        let hangingLegRaisesInterval = IntervalStep(.work, step: hangingLegRaisesStep)
        
        let coreBlock = IntervalBlock(steps: [lSitHoldInterval, recoveryInterval, hangingLegRaisesInterval, recoveryInterval], iterations: 2)

        let coreWorkout = CustomWorkout(
            activity: .coreTraining,
            location: .indoor,
            displayName: "Core",
            blocks: [coreBlock],
        )

        // Cooldown
        let cooldownStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Cooldown")
        let cooldownInterval = IntervalStep(.work, step: cooldownStep)
        let cooldownBlock = IntervalBlock(steps: [cooldownInterval], iterations: 1)
        let cooldownWorkout = CustomWorkout(
            activity: .cooldown,
            location: .indoor,
            displayName: "Cooldown",
            blocks: [cooldownBlock]
        )
        
        return WorkoutSequence(
            workouts: [warmupWorkout, cyclingWorkout, lowerBodyStrengthWorkout, coreWorkout, cooldownWorkout],
            displayName: "Lower Body Strength"
        )
    }

    private func createCardioWorkoutSequence() async -> WorkoutSequence {
        
        // Initialize Recovery Step
        let recoveryStep = WorkoutStep(goal: .open, displayName: "Rest")
        let recoveryInterval = IntervalStep(.recovery, step: recoveryStep)
        
        // Warmup
        let warmupStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Warmup")
        let warmupInterval = IntervalStep(.work, step: warmupStep)
        let warmupBlock = IntervalBlock(steps: [warmupInterval], iterations: 1)
        let warmupWorkout = CustomWorkout(
            activity: .flexibility,
            location: .indoor,
            displayName: "Warmup",
            blocks: [warmupBlock]
        )
        
        // Cycling Warmup
        let cyclingStep = WorkoutStep(goal: .time(600, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling")
        let cyclingInterval = IntervalStep(.work, step: cyclingStep)
        let cyclingBlock = IntervalBlock(steps: [cyclingInterval, recoveryInterval], iterations: 1)
        let cyclingWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cycling",
            blocks: [cyclingBlock]
        )

        // Running Workout
        let runningStep = WorkoutStep(goal: .time(1800, .seconds), alert: .speed(6.5, unit: .kilometersPerHour), displayName: "Running")
        let runningInterval = IntervalStep(.work, step: runningStep)
        let runningBlock = IntervalBlock(steps: [runningInterval, recoveryInterval], iterations: 1)
        let runningWorkout = CustomWorkout(
            activity: .running,
            location: .indoor,
            displayName: "Running",
            blocks: [runningBlock]
        )
        
        // Jump rope Workout
        let jumpRopeStep = WorkoutStep(goal: .time(180, .seconds), displayName: "Jump Rope")
        let jumpRopeInterval = IntervalStep(.work, step: jumpRopeStep)
        let jumpRopeBlock = IntervalBlock(steps: [jumpRopeInterval, recoveryInterval], iterations: 3)
        let jumpRopeWorkout = CustomWorkout(
            activity: .jumpRope,
            location: .indoor,
            displayName: "Jump Rope",
            blocks: [jumpRopeBlock]
        )

        // Cooldown
        let cooldownStep = WorkoutStep(goal: .time(300, .seconds), displayName: "Cooldown")
        let cooldownInterval = IntervalStep(.work, step: cooldownStep)
        let cooldownBlock = IntervalBlock(steps: [cooldownInterval], iterations: 1)
        let cooldownWorkout = CustomWorkout(
            activity: .cooldown,
            location: .indoor,
            displayName: "Cooldown",
            blocks: [cooldownBlock]
        )
        
        return WorkoutSequence(
            workouts: [warmupWorkout, cyclingWorkout, runningWorkout, jumpRopeWorkout, cooldownWorkout],
            displayName: "Cardio"
        )
    }


}

#Preview {
    ContentView()
}
