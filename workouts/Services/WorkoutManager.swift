import Foundation
import WorkoutKit

class WorkoutManager: ObservableObject {
    
    static let shared = WorkoutManager()
    @Published var workoutSequences: [WorkoutSequence] = []

    func createWorkouts() async {
        // Create individual workout sequences
        let upperBodySequence = createUpperBodyStrengthWorkoutSequence()
        let complementaryUpperBodySequence = createComplementaryUpperBodyStrengthWorkoutSequence()
        let lowerBodySequence = createLowerBodyStrengthWorkoutSequence()
        let lowerBodyEnduranceSequence = createLowerBodyEnduranceWorkoutSequence()
        let fullBodyEnduranceSequence = createFullBodyEnduranceWorkoutSequence()
        let fullBodyStrengthSequence = createFullBodyStrengthWorkoutSequence()
        
        // Add sequences to the array
        workoutSequences.append(upperBodySequence)
        workoutSequences.append(complementaryUpperBodySequence)
        workoutSequences.append(lowerBodySequence)
        workoutSequences.append(lowerBodyEnduranceSequence)
        workoutSequences.append(fullBodyEnduranceSequence)
        workoutSequences.append(fullBodyStrengthSequence)
        
    }

    private func createUpperBodyStrengthWorkoutSequence() -> WorkoutSequence {
        
        // Initialize Recovery Steps
        let recoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .open, displayName: "Rest"))
        let shortRest = IntervalStep(.recovery, step: WorkoutStep(goal: .time(30, .seconds), displayName: "Rest"))

        // Upper Body Calisthenics Warmup
        let calisthenicsBackExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Pull Ups"))
        let calisthenicsChestExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Dips"))
        let upperBodyCalisthenicsWarmup = IntervalBlock(steps: [calisthenicsBackExercise, shortRest, calisthenicsChestExercise, shortRest], iterations: 2)

        // Back Functional Strength
        let compoundBackExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Lat Pulldown"))
        let backFunctionalStrength = IntervalBlock(steps: [compoundBackExercise, recoveryInterval], iterations: 3)

        // Chest Functional Strength
        let compoundChestExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Bench Press"))
        let chestFunctionalStrength = IntervalBlock(steps: [compoundChestExercise, recoveryInterval], iterations: 3)

        // Back Muscular Endurance
        let backIsometricExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Cable Pullover"))
        let backMuscularEndurance = IntervalBlock(steps: [backIsometricExercise, recoveryInterval], iterations: 3)

        // Chest Muscular Endurance
        let chestIsometricExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Chest Flys"))
        let chestMuscularEndurance = IntervalBlock(steps: [chestIsometricExercise, recoveryInterval], iterations: 3)
        
        // Create Custom Workout
        let upperBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Functional Strength",
            blocks: [upperBodyCalisthenicsWarmup, backFunctionalStrength, chestFunctionalStrength, backMuscularEndurance, chestMuscularEndurance],
        )
        
        return WorkoutSequence(
            workouts: [upperBodyStrengthWorkout],
            displayName: "Upper Body Strength"
        )
    }

    private func createLowerBodyStrengthWorkoutSequence() -> WorkoutSequence {
        
        // Initialize Recovery Steps
        let recoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .open, displayName: "Rest"))
        let timedRecoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .time(30, .seconds), displayName: "Rest"))
        
        // Lower Body Cardio Warmup
        let cyclingWarmupExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(300, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling"))
        let cardioWarmup = IntervalBlock(steps: [cyclingWarmupExercise], iterations: 1)

        // Lower Body Hip Warmup
        let adductorsExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Adductors"))
        let abductorsExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Abductors"))
        let hipWarmup = IntervalBlock(steps: [adductorsExercise, recoveryInterval, abductorsExercise, recoveryInterval], iterations: 2)
        
        // Front Lower Body Functional Strength
        let compoundFrontLowerBodyExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Barbell Back Squats"))
        let frontLowerBodyFunctionalStrength = IntervalBlock(steps: [compoundFrontLowerBodyExercise, recoveryInterval], iterations: 3)

        // Back Lower Body Functional Strength
        let compoundBackLowerBodyExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Barbell Deadlifts"))
        let backLowerBodyFunctionalStrength = IntervalBlock(steps: [compoundBackLowerBodyExercise, recoveryInterval], iterations: 3)

        // Lower Body Functional Stability 
        let balancedCalfExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Single-Leg Calf Raises"))
        let lowerBodyFunctionalStability = IntervalBlock(steps: [balancedCalfExercise,recoveryInterval], iterations: 3)
        
        // Core Functional Stability
        let hangingCoreHoldExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(30, .seconds), displayName: "L-Sit Hold"))
        let hangingCoreCrunchExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(30, .seconds), displayName: "Hanging Leg Raises"))
        let coreFunctionalStability = IntervalBlock(steps: [hangingCoreHoldExercise, timedRecoveryInterval, hangingCoreCrunchExercise, timedRecoveryInterval], iterations: 2)

        // Create Custom Workouts
        let cardioWarmupWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cardio Warmup",
            blocks: [cardioWarmup]
        )

        let functionalStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Functional Strength",
            blocks: [hipWarmup, frontLowerBodyFunctionalStrength, backLowerBodyFunctionalStrength, lowerBodyFunctionalStability],
        )
        
        let functionalStabilityWorkout = CustomWorkout(
            activity: .coreTraining,
            location: .indoor,
            displayName: "Functional Stability",
            blocks: [coreFunctionalStability],
        )
        
        return WorkoutSequence(
            workouts: [cardioWarmupWorkout, functionalStrengthWorkout, functionalStabilityWorkout],
            displayName: "Lower Body Strength"
        )
    }

    private func createLowerBodyEnduranceWorkoutSequence() -> WorkoutSequence {
        
        // Initialize Recovery Steps
        let timedRecoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .time(30, .seconds), displayName: "Rest"))
        
        // Lower Body Cardio Warmup
        let cyclingWarmupExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(300, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling"))
        let cardioWarmup = IntervalBlock(steps: [cyclingWarmupExercise], iterations: 1)
        
        // Paced Run
        let continousRunningExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(1800, .seconds), alert: .speed(10, unit: .kilometersPerHour), displayName: "Continous Running"))
        let pacedRun = IntervalBlock(steps: [continousRunningExercise], iterations: 1)
        
        // Lower Body Plyometrics
        let jumpRopeExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(90, .seconds), alert: .heartRate(zone: 4), displayName: "Jump Rope"))
        let plyometrics = IntervalBlock(steps: [jumpRopeExercise, timedRecoveryInterval], iterations: 3)

        // Create Custom Workouts
        let cardioWarmupWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cardio Warmup",
            blocks: [cardioWarmup]
        )
        
        let pacedRunWorkout = CustomWorkout(
            activity: .running,
            location: .indoor,
            displayName: "Paced Run",
            blocks: [pacedRun]
        )
        
        let plyometricsWorkout = CustomWorkout(
            activity: .highIntensityIntervalTraining,
            location: .indoor,
            displayName: "Plyometrics",
            blocks: [plyometrics]
        )
        
        return WorkoutSequence(
            workouts: [cardioWarmupWorkout, pacedRunWorkout, plyometricsWorkout],
            displayName: "Lower Body Endurance"
        )
    }

    private func createComplementaryUpperBodyStrengthWorkoutSequence() -> WorkoutSequence {
        
        // Initialize Recovery Step
        let recoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .open, displayName: "Rest"))

        // Complementary Upper Body Calisthenics Warmup
        let calisthenicsBicepsExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Chin Ups"))
        let calisthenicsTricepsExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Dips"))
        let complementaryUpperBodyCalisthenicsWarmup = IntervalBlock(steps: [calisthenicsBicepsExercise, recoveryInterval, calisthenicsTricepsExercise, recoveryInterval], iterations: 2)

        // Isolated Biceps Strength
        let isolatedBicepsExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Bicep Curls"))
        let isolatedBicepsStrength = IntervalBlock(steps: [isolatedBicepsExercise, recoveryInterval], iterations: 2)

        // Isolated Triceps Strength
        let isolatedTricepsExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Triceps Extension"))
        let isolatedTricepsStrength = IntervalBlock(steps: [isolatedTricepsExercise, recoveryInterval], iterations: 2)

        // Isolated Lateral Raises
        let isolatedShoulderExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Lateral Raises"))
        let isolatedShoulderStrength = IntervalBlock(steps: [isolatedShoulderExercise, recoveryInterval], iterations: 2)
        
        // Create Custom Workout
        let upperBodyStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Complementary Strength",
            blocks: [complementaryUpperBodyCalisthenicsWarmup, isolatedBicepsStrength, isolatedTricepsStrength, isolatedShoulderStrength],
        )
        
        return WorkoutSequence(
            workouts: [upperBodyStrengthWorkout],
            displayName: "Complementary Upper Body Strength"
        )
    }

    private func createFullBodyEnduranceWorkoutSequence() -> WorkoutSequence {
        
        // Initialize Recovery Steps
        let timedRecoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .time(30, .seconds), displayName: "Rest"))
        let sprintsRecoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .time(30, .seconds), displayName: "Rest"))
        
        // Lower Body Cardio Warmup
        let cyclingWarmupExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(300, .seconds), alert: .heartRate(zone: 2), displayName: "Cycling"))
        let cardioWarmup = IntervalBlock(steps: [cyclingWarmupExercise], iterations: 1)
        
        // Lower Body Plyometrics
        let jumpRopeExercise = IntervalStep(.work, step: WorkoutStep(goal: .time(90, .seconds), alert: .heartRate(zone: 4), displayName: "Jump Rope"))
        let plyometrics = IntervalBlock(steps: [jumpRopeExercise, timedRecoveryInterval], iterations: 3)

        // Sprints
        let sprintExercise = IntervalStep(.work, step: WorkoutStep(goal: .distance(400, .meters), alert: .heartRate(zone: 5), displayName: "Sprints"))
        let sprints = IntervalBlock(steps: [sprintExercise, sprintsRecoveryInterval], iterations: 3)

        // Create Custom Workouts
        let cardioWarmupWorkout = CustomWorkout(
            activity: .cycling,
            location: .indoor,
            displayName: "Cardio Warmup",
            blocks: [cardioWarmup]
        )

        let plyometricsWorkout = CustomWorkout(
            activity: .highIntensityIntervalTraining,
            location: .indoor,
            displayName: "Plyometrics",
            blocks: [plyometrics],
        )

        let sprintsWorkout = CustomWorkout(
            activity: .running,
            location: .indoor,
            displayName: "Sprints",
            blocks: [sprints],
        )
        
        return WorkoutSequence(
            workouts: [cardioWarmupWorkout, plyometricsWorkout, sprintsWorkout],
            displayName: "Full Body Endurance"
        )
    }

    private func createFullBodyStrengthWorkoutSequence() -> WorkoutSequence {

        // Initialize Recovery Steps
        let recoveryInterval = IntervalStep(.recovery, step: WorkoutStep(goal: .open, displayName: "Rest"))

        // Upper Body Calisthenics Warmup
        let calisthenicsBackExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Pull Ups"))
        let calisthenicsChestExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Dips"))
        let upperBodyCalisthenicsWarmup = IntervalBlock(steps: [calisthenicsBackExercise, recoveryInterval, calisthenicsChestExercise, recoveryInterval], iterations: 2)

        // Lower Body Calisthenics Warmup

        // Back Functional Strength
        let compoundBackExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Lat Pulldown"))
        let backFunctionalStrength = IntervalBlock(steps: [compoundBackExercise, recoveryInterval], iterations: 3)

        // Chest Functional Strength
        let compoundChestExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Bench Press"))
        let chestFunctionalStrength = IntervalBlock(steps: [compoundChestExercise, recoveryInterval], iterations: 3)

        // Front Lower Body Functional Strength
        let compoundFrontLowerBodyExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Barbell Back Squats"))
        let frontLowerBodyFunctionalStrength = IntervalBlock(steps: [compoundFrontLowerBodyExercise, recoveryInterval], iterations: 3)

        // Back Lower Body Functional Strength
        let compoundBackLowerBodyExercise = IntervalStep(.work, step: WorkoutStep(goal: .open, displayName: "Barbell Deadlifts"))
        let backLowerBodyFunctionalStrength = IntervalBlock(steps: [compoundBackLowerBodyExercise, recoveryInterval], iterations: 3)

        let functionalStrengthWorkout = CustomWorkout(
            activity: .traditionalStrengthTraining,
            location: .indoor,
            displayName: "Functional Strength",
            blocks: [upperBodyCalisthenicsWarmup, backFunctionalStrength, chestFunctionalStrength, frontLowerBodyFunctionalStrength, backLowerBodyFunctionalStrength],
        )
        
        return WorkoutSequence(
            workouts: [functionalStrengthWorkout],
            displayName: "Full Body Strength"
        )
    }
}

