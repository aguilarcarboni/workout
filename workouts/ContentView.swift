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
                .navigationTitle("Workout")
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
        let complementaryUpperBodySequence = await createComplementaryUpperBodyStrengthWorkoutSequence()
        let lowerBodySequence = await createLowerBodyStrengthWorkoutSequence()
        let cardioSequence = await createCardioWorkoutSequence()
        
        // Add sequences to the array
        workoutSequences.append(upperBodySequence)
        workoutSequences.append(complementaryUpperBodySequence)
        workoutSequences.append(lowerBodySequence)
        workoutSequences.append(cardioSequence)
    }

    private func createComplementaryUpperBodyStrengthWorkoutSequence() async -> WorkoutSequence {
        
        // Initialize Recovery Step
        // Used to let the user go to the machine and/or rest
        let recoveryStep = WorkoutStep(goal: .open, displayName: "Rest")
        let recoveryInterval = IntervalStep(.recovery, step: recoveryStep)

        // Complementary Upper Body Calisthenics Warmup
        let chinUpsStep = WorkoutStep(goal: .open, displayName: "Chin Ups")
        let chinUpsInterval = IntervalStep(.work, step: chinUpsStep)
        let dipsStep = WorkoutStep(goal: .open, displayName: "Dips")
        let dipsInterval = IntervalStep(.work, step: dipsStep)
        let calisthenicsBlock = IntervalBlock(steps: [chinUpsInterval, recoveryInterval, dipsInterval, recoveryInterval], iterations: 2)

        // Complementary Upper Body Strength
        let bicepCurlsStep = WorkoutStep(goal: .open, displayName: "Bicep Curls")
        let bicepCurlsInterval = IntervalStep(.work, step: bicepCurlsStep)
        let bicepCurlsBlock = IntervalBlock(steps: [bicepCurlsInterval, recoveryInterval], iterations: 2)

        let tricepsExtensionStep = WorkoutStep(goal: .open, displayName: "Triceps Extension") 
        let tricepsExtensionInterval = IntervalStep(.work, step: tricepsExtensionStep)
        let tricepsExtensionBlock = IntervalBlock(steps: [tricepsExtensionInterval, recoveryInterval], iterations: 2)

        let lateralRaisesStep = WorkoutStep(goal: .open, displayName: "Lateral Raises") 
        let lateralRaisesInterval = IntervalStep(.work, step: lateralRaisesStep)
        let lateralRaisesBlock = IntervalBlock(steps: [lateralRaisesInterval, recoveryInterval], iterations: 2)

        // Upper Body Muscular Endurance
        let preacherCurlStep = WorkoutStep(goal: .open, displayName: "Preacher Curl")
        let preacherCurlInterval = IntervalStep(.work, step: preacherCurlStep)
        let preacherCurlBlock = IntervalBlock(steps: [preacherCurlInterval, recoveryInterval], iterations: 2)

        let singleArmTricepsExtensionStep = WorkoutStep(goal: .open, displayName: "Single-Arm Triceps Extension")
        let singleArmTricepsExtensionInterval = IntervalStep(.work, step: singleArmTricepsExtensionStep)
        let singleArmTricepsExtensionBlock = IntervalBlock(steps: [singleArmTricepsExtensionInterval, recoveryInterval], iterations: 2)

        let tricepsPushdownStep = WorkoutStep(goal: .open, displayName: "Triceps Pushdown")
        let tricepsPushdownInterval = IntervalStep(.work, step: tricepsPushdownStep)
        let tricepsPushdownBlock = IntervalBlock(steps: [tricepsPushdownInterval, recoveryInterval], iterations: 2)
        
        // Create Custom Workout
        let upperBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Complementary Strength",
            blocks: [calisthenicsBlock, bicepCurlsBlock, tricepsExtensionBlock, lateralRaisesBlock, preacherCurlBlock, singleArmTricepsExtensionBlock, tricepsPushdownBlock],
        )
        
        return WorkoutSequence(
            workouts: [upperBodyStrengthWorkout],
            displayName: "Complementary Upper Body"
        )
    }

    private func createUpperBodyStrengthWorkoutSequence() async -> WorkoutSequence {
        
        // Initialize Recovery Step
        // Used to let the user go to the machine and/or rest
        let recoveryStep = WorkoutStep(goal: .open, displayName: "Rest")
        let recoveryInterval = IntervalStep(.recovery, step: recoveryStep)

        // Upper Body Calisthenics Warmup
        let pullUpsStep = WorkoutStep(goal: .open, displayName: "Pull Ups")
        let pullUpsInterval = IntervalStep(.work, step: pullUpsStep)
        let dipsStep = WorkoutStep(goal: .open, displayName: "Dips")
        let dipsInterval = IntervalStep(.work, step: dipsStep)
        let calisthenicsBlock = IntervalBlock(steps: [pullUpsInterval, recoveryInterval, dipsInterval, recoveryInterval], iterations: 2)

        // Upper Body Functional Strength
        let latPulldownStep = WorkoutStep(goal: .open, displayName: "Lat Pulldown")
        let latPullDownInterval = IntervalStep(.work, step: latPulldownStep)
        let latPulldownBlock = IntervalBlock(steps: [latPullDownInterval, recoveryInterval], iterations: 3)

        let benchPressStep = WorkoutStep(goal: .open, displayName: "Bench Press") 
        let benchPressInterval = IntervalStep(.work, step: benchPressStep)
        let benchPressBlock = IntervalBlock(steps: [benchPressInterval, recoveryInterval], iterations: 3)

        // Upper Body Muscular Endurance
        let pullbackStep = WorkoutStep(goal: .open, displayName: "Cable Pullover")
        let pullbackInterval = IntervalStep(.work, step: pullbackStep)
        let pullbackBlock = IntervalBlock(steps: [pullbackInterval, recoveryInterval], iterations: 3)

        let chestFlyStep = WorkoutStep(goal: .open, displayName: "Chest Flys")
        let chestFlyInterval = IntervalStep(.work, step: chestFlyStep)
        let chestFlyBlock = IntervalBlock(steps: [chestFlyInterval, recoveryInterval], iterations: 3)
        
        // Create Custom Workout
        let upperBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Functional Strength",
            blocks: [calisthenicsBlock, latPulldownBlock, benchPressBlock, pullbackBlock, chestFlyBlock],
        )
        
        return WorkoutSequence(
            workouts: [upperBodyStrengthWorkout],
            displayName: "Upper Body"
        )
    }

    private func createLowerBodyStrengthWorkoutSequence() async -> WorkoutSequence {
        
        // Initialize Recovery Steps
        let recoveryStep = WorkoutStep(goal: .open, displayName: "Rest")
        let recoveryInterval = IntervalStep(.recovery, step: recoveryStep)

        let timedRecoveryStep = WorkoutStep(goal: .time(30, .seconds), displayName: "Rest")
        let timedRecoveryInterval = IntervalStep(.recovery, step: timedRecoveryStep)
        
        // Lower Body Cardio Warmup
        let cyclingStep = WorkoutStep(goal: .time(300, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling")
        let cyclingInterval = IntervalStep(.work, step: cyclingStep)
        let cyclingBlock = IntervalBlock(steps: [cyclingInterval], iterations: 1)

        // Lower Body Hip Warmup
        let abductorsStep = WorkoutStep(goal: .open, displayName: "Abductors")
        let abductorsInterval = IntervalStep(.work, step: abductorsStep)
        
        let adductorsStep = WorkoutStep(goal: .open, displayName: "Adductors")
        let adductorsInterval = IntervalStep(.work, step: adductorsStep)
        
        let abductorsBlock = IntervalBlock(steps: [abductorsInterval, recoveryInterval, adductorsInterval, recoveryInterval], iterations: 2)
        
        // Lower Body Functional Strength
        let squatsStep = WorkoutStep(goal: .open, displayName: "Barbell Back Squats")
        let squatsInterval = IntervalStep(.work, step: squatsStep)
        let squatsBlock = IntervalBlock(steps: [squatsInterval, recoveryInterval], iterations: 3)

        let deadliftsStep = WorkoutStep(goal: .open, displayName: "Barbell Deadlifts")
        let deadliftsInterval = IntervalStep(.work, step: deadliftsStep)
        let deadliftsBlock = IntervalBlock(steps: [deadliftsInterval, recoveryInterval], iterations: 3)

        // Lower Body Functional Stability
        let calfRaisesStep = WorkoutStep(goal: .open, displayName: "Single-Leg Calf Raises")
        let calfRaisesInterval = IntervalStep(.work, step: calfRaisesStep)
        let calfRaisesBlock = IntervalBlock(steps: [calfRaisesInterval,recoveryInterval], iterations: 3)
        
        // Core Functional Stability
        let lSitHoldStep = WorkoutStep(goal: .time(30, .seconds), displayName: "L-Sit Hold")
        let lSitHoldInterval = IntervalStep(.work, step: lSitHoldStep)
        
        let hangingLegRaisesStep = WorkoutStep(goal: .time(30, .seconds), displayName: "Hanging Leg Raises")
        let hangingLegRaisesInterval = IntervalStep(.work, step: hangingLegRaisesStep)

        let coreBlock = IntervalBlock(steps: [lSitHoldInterval, timedRecoveryInterval, hangingLegRaisesInterval, timedRecoveryInterval], iterations: 2)

        // Create Custom Workouts for Apple Fitness Sync
        let cyclingWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cardio Warmup",
            blocks: [cyclingBlock]
        )

        let lowerBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Functional Strength",
            blocks: [abductorsBlock, squatsBlock, deadliftsBlock, calfRaisesBlock],
        )
        
        let coreWorkout = CustomWorkout(
            activity: .coreTraining,
            location: .indoor,
            displayName: "Functional Stability",
            blocks: [coreBlock],
        )
        
        return WorkoutSequence(
            workouts: [cyclingWorkout, lowerBodyStrengthWorkout, coreWorkout],
            displayName: "Lower Body"
        )
    }

    private func createCardioWorkoutSequence() async -> WorkoutSequence {
        
        // Initialize Recovery Step
        let timedRecoveryStep = WorkoutStep(goal: .time(30, .seconds), displayName: "Rest")
        let timedRecoveryInterval = IntervalStep(.recovery, step: timedRecoveryStep)
        
        // Lower Body Cardio Warmup
        let cyclingStep = WorkoutStep(goal: .time(300, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling")
        let cyclingInterval = IntervalStep(.work, step: cyclingStep)
        let cyclingBlock = IntervalBlock(steps: [cyclingInterval], iterations: 1)

        // Paced Run
        let runningStep = WorkoutStep(goal: .time(1800, .seconds), alert: .speed(10, unit: .kilometersPerHour), displayName: "Running")
        let runningInterval = IntervalStep(.work, step: runningStep)
        let runningBlock = IntervalBlock(steps: [runningInterval], iterations: 1)
        
        // Lower Body Functional Agility
        let jumpRopeStep = WorkoutStep(goal: .time(90, .seconds), displayName: "Work")
        let jumpRopeInterval = IntervalStep(.work, step: jumpRopeStep)
        let jumpRopeBlock = IntervalBlock(steps: [jumpRopeInterval, timedRecoveryInterval], iterations: 5)
        
        // Create Custom Workouts
        let cyclingWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cardio Warmup",
            blocks: [cyclingBlock]
        )
        
        let runningWorkout = CustomWorkout(
            activity: .running,
            location: .indoor,
            displayName: "Paced Run",
            blocks: [runningBlock]
        )
        
        let jumpRopeWorkout = CustomWorkout(
            activity: .highIntensityIntervalTraining,
            location: .indoor,
            displayName: "Plyometrics",
            blocks: [jumpRopeBlock]
        )
        
        return WorkoutSequence(
            workouts: [cyclingWorkout, runningWorkout, jumpRopeWorkout],
            displayName: "Cardio"
        )
    }


}

#Preview {
    ContentView()
}
