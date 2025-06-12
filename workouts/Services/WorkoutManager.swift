import Foundation
import WorkoutKit
import HealthKit

// MARK: - Protocols

/// Protocol for any component that can be converted to WorkoutKit types
protocol WorkoutKitConvertible {
    associatedtype WorkoutKitType
    func toWorkoutKitType() -> WorkoutKitType
}

/// Protocol for workout components that have goals and can be tracked
protocol TrackableComponent {
    var displayName: String { get }
    var goal: WorkoutGoal { get }
}

/// Protocol for components that can have iterations/repetitions
protocol RepeatableComponent {
    var iterations: Int { get }
}

// MARK: - Core Fitness Types

/**
 * Exercise: A physical or mental activity that an athlete can do to improve their fitness metrics
 * 
 * Maps to WorkoutKit: IntervalStep (.work type)
 * - Defines the actual work being performed
 * - Can have specific goals (time, distance, calories, etc.)
 * - Can have alerts for pacing, heart rate, etc.
 */
class Exercise: TrackableComponent, WorkoutKitConvertible {
    typealias WorkoutKitType = IntervalStep
    
    let displayName: String
    let goal: WorkoutGoal
    let alert: (any WorkoutAlert)?
    
    init(displayName: String, goal: WorkoutGoal, alert: (any WorkoutAlert)? = nil) {
        self.displayName = displayName
        self.goal = goal
        self.alert = alert
    }
    
    /// Converts this Exercise to a WorkoutKit IntervalStep
    func toWorkoutKitType() -> IntervalStep {
        let workoutStep = WorkoutStep(goal: goal, alert: alert, displayName: displayName)
        return IntervalStep(.work, step: workoutStep)
    }
    
    /// Legacy method name for backward compatibility
    func toIntervalStep() -> IntervalStep {
        return toWorkoutKitType()
    }
}

/**
 * Rest: A physical or mental rest that an athlete can do between exercises
 * 
 * Maps to WorkoutKit: IntervalStep (.recovery type)
 * - Defines recovery periods between work intervals
 * - Usually has time-based goals but can be open-ended
 */
class Rest: TrackableComponent, WorkoutKitConvertible {
    typealias WorkoutKitType = IntervalStep
    
    let displayName: String
    let goal: WorkoutGoal
    
    init(displayName: String = "Rest", goal: WorkoutGoal = .open) {
        self.displayName = displayName
        self.goal = goal
    }
    
    /// Converts this Rest to a WorkoutKit IntervalStep
    func toWorkoutKitType() -> IntervalStep {
        let workoutStep = WorkoutStep(goal: goal, displayName: displayName)
        return IntervalStep(.recovery, step: workoutStep)
    }
    
    /// Legacy method name for backward compatibility
    func toIntervalStep() -> IntervalStep {
        return toWorkoutKitType()
    }
}

/**
 * Workout: A group of exercises and rest periods that help improve fitness metrics
 * 
 * Maps to WorkoutKit: IntervalBlock
 * - Combines exercises with rest periods in a structured format
 * - Can be repeated multiple times (iterations)
 * - Represents a cohesive training block
 */
class Workout: RepeatableComponent, WorkoutKitConvertible {
    typealias WorkoutKitType = IntervalBlock
    
    let exercises: [Exercise]
    let restPeriods: [Rest]
    let iterations: Int
    let displayName: String
    
    init(exercises: [Exercise], restPeriods: [Rest], iterations: Int = 1, displayName: String) {
        self.exercises = exercises
        self.restPeriods = restPeriods
        self.iterations = iterations
        self.displayName = displayName
    }
    
    /// Converts this Workout to a WorkoutKit IntervalBlock
    func toWorkoutKitType() -> IntervalBlock {
        var steps: [IntervalStep] = []
        
        // Interleave exercises with rest periods
        for i in 0..<exercises.count {
            steps.append(exercises[i].toWorkoutKitType())
            if i < restPeriods.count {
                steps.append(restPeriods[i].toWorkoutKitType())
            }
        }
        
        return IntervalBlock(steps: steps, iterations: iterations)
    }
    
    /// Legacy method name for backward compatibility
    func toIntervalBlock() -> IntervalBlock {
        return toWorkoutKitType()
    }
}

/**
 * Warmup: A preparation phase to ready the body for main workout
 * 
 * Maps to WorkoutKit: Collection of IntervalBlocks (via contained workouts)
 * - Prepares the body for the main training
 * - Usually lower intensity than main workout
 * - Can contain multiple workout components
 */
class Warmup: WorkoutKitConvertible {
    typealias WorkoutKitType = [IntervalBlock]
    
    let workouts: [Workout]
    let displayName: String
    
    init(workouts: [Workout], displayName: String = "Warmup") {
        self.workouts = workouts
        self.displayName = displayName
    }
    
    /// Converts this Warmup to WorkoutKit IntervalBlocks
    func toWorkoutKitType() -> [IntervalBlock] {
        return workouts.map { $0.toWorkoutKitType() }
    }
    
    /// Legacy method name for backward compatibility
    func toIntervalBlocks() -> [IntervalBlock] {
        return toWorkoutKitType()
    }
}

/**
 * Cooldown: A recovery phase to help the body recover after main workout
 * 
 * Maps to WorkoutKit: Collection of IntervalBlocks (via contained workouts)
 * - Helps the body transition from high activity to rest
 * - Usually lower intensity recovery movements
 * - Can contain multiple workout components
 */
class Cooldown: WorkoutKitConvertible {
    typealias WorkoutKitType = [IntervalBlock]
    
    let workouts: [Workout]
    let displayName: String
    
    init(workouts: [Workout], displayName: String = "Cooldown") {
        self.workouts = workouts
        self.displayName = displayName
    }
    
    /// Converts this Cooldown to WorkoutKit IntervalBlocks
    func toWorkoutKitType() -> [IntervalBlock] {
        return workouts.map { $0.toWorkoutKitType() }
    }
    
    /// Legacy method name for backward compatibility
    func toIntervalBlocks() -> [IntervalBlock] {
        return toWorkoutKitType()
    }
}

/**
 * WorkoutSequence: A key part of a Training Session - a set of workouts with similar properties
 * 
 * Maps to WorkoutKit: CustomWorkout
 * - Groups workouts that can be tracked together under one activity type
 * - Defines the activity type and location for WorkoutKit tracking
 * - Represents a cohesive training sequence that can be sent to Apple Watch
 */
class WorkoutSequence: WorkoutKitConvertible, Identifiable, ObservableObject {
    typealias WorkoutKitType = CustomWorkout
    
    let id = UUID()
    let workouts: [Workout]
    let displayName: String
    let activity: HKWorkoutActivityType
    let location: HKWorkoutSessionLocationType
    
    init(workouts: [Workout], displayName: String, activity: HKWorkoutActivityType, location: HKWorkoutSessionLocationType) {
        self.workouts = workouts
        self.displayName = displayName
        self.activity = activity
        self.location = location
    }
    
    /// Converts this WorkoutSequence to a WorkoutKit CustomWorkout
    func toWorkoutKitType() -> CustomWorkout {
        let blocks = workouts.map { $0.toWorkoutKitType() }
        return CustomWorkout(
            activity: activity,
            location: location,
            displayName: displayName,
            blocks: blocks
        )
    }
    
    /// Legacy method name for backward compatibility
    func toCustomWorkout() -> CustomWorkout {
        return toWorkoutKitType()
    }
}

/**
 * TrainingSession: A complete training session for a single day
 * 
 * Maps to WorkoutKit: Collection of CustomWorkouts
 * - Represents a complete day of training
 * - Can include warmup, multiple workout sequences, and cooldown
 * - Each component becomes a separate CustomWorkout for Apple Watch tracking
 */
class TrainingSession: WorkoutKitConvertible, Identifiable {
    typealias WorkoutKitType = [CustomWorkout]
    
    let id = UUID()
    
    let warmup: Warmup?
    let workoutSequences: [WorkoutSequence]
    let cooldown: Cooldown?
    let displayName: String
    
    init(warmup: Warmup? = nil, workoutSequences: [WorkoutSequence], cooldown: Cooldown? = nil, displayName: String) {
        self.warmup = warmup
        self.workoutSequences = workoutSequences
        self.cooldown = cooldown
        self.displayName = displayName
    }
    
    /// Converts this TrainingSession to WorkoutKit CustomWorkouts
    func toWorkoutKitType() -> [CustomWorkout] {
        var customWorkouts: [CustomWorkout] = []
        
        // Add warmup as a custom workout if present
        if let warmup = warmup, !warmup.workouts.isEmpty {
            let warmupWorkout = CustomWorkout(
                activity: .other,
                location: .indoor,
                displayName: warmup.displayName,
                blocks: warmup.toWorkoutKitType()
            )
            customWorkouts.append(warmupWorkout)
        }
        
        // Add all workout sequences
        customWorkouts.append(contentsOf: workoutSequences.map { $0.toWorkoutKitType() })
        
        // Add cooldown as a custom workout if present
        if let cooldown = cooldown, !cooldown.workouts.isEmpty {
            let cooldownWorkout = CustomWorkout(
                activity: .other,
                location: .indoor,
                displayName: cooldown.displayName,
                blocks: cooldown.toWorkoutKitType()
            )
            customWorkouts.append(cooldownWorkout)
        }
        
        return customWorkouts
    }
    
    /// Legacy method name for backward compatibility
    func toCustomWorkouts() -> [CustomWorkout] {
        return toWorkoutKitType()
    }
}

// MARK: - Workout Manager

/**
 * WorkoutManager: Central manager for all training sessions and workout operations
 * 
 * Responsibilities:
 * - Store and manage all training sessions
 * - Create predefined workout templates
 * - Provide access to workout sequences for UI components
 * - Bridge between our OOP structure and WorkoutKit integration
 */
class WorkoutManager: ObservableObject {
    
    static let shared = WorkoutManager()
    
    /// All available training sessions
    @Published var trainingSessions: [TrainingSession] = []
    
    /// Initializes the workout manager with predefined training sessions
    func createWorkouts() async {
        let sessions = await createPredefinedTrainingSessions()
        
        await MainActor.run {
            self.trainingSessions = sessions
        }
    }
    
    /// Creates all predefined training sessions
    private func createPredefinedTrainingSessions() async -> [TrainingSession] {
        return [
            createUpperBodyStrengthTrainingSession(),
            createComplementaryUpperBodyStrengthTrainingSession(),
            createLowerBodyStrengthTrainingSession(),
            createLowerBodyEnduranceTrainingSession(),
            createFullBodyEnduranceTrainingSession(),
            createFullBodyStrengthTrainingSession()
        ]
    }

    // MARK: - Training Session Builders
    
    private func createUpperBodyStrengthTrainingSession() -> TrainingSession {
        // Create exercises
        let pullUps = Exercise(displayName: "Pull Ups", goal: .open)
        let dips = Exercise(displayName: "Dips", goal: .open)
        let latPulldown = Exercise(displayName: "Lat Pulldown", goal: .open)
        let benchPress = Exercise(displayName: "Bench Press", goal: .open)
        let cablePullover = Exercise(displayName: "Cable Pullover", goal: .open)
        let chestFlys = Exercise(displayName: "Chest Flys", goal: .open)
        
        // Create rest periods
        let shortRest = Rest(goal: .time(30, .seconds))
        let openRest = Rest()
        
        // Create workouts - Upper Body Calisthenics Warmup is part of the main sequence
        let upperBodyCalisthenicsWarmup = Workout(
            exercises: [pullUps, dips],
            restPeriods: [shortRest, shortRest],
            iterations: 2,
            displayName: "Upper Body Calisthenics Warmup"
        )
        
        let backFunctionalStrength = Workout(
            exercises: [latPulldown],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Functional Strength"
        )
        
        let chestFunctionalStrength = Workout(
            exercises: [benchPress],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Chest Functional Strength"
        )
        
        let chestMuscularEndurance = Workout(
            exercises: [chestFlys],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Chest Muscular Endurance"
        )
        
        let backMuscularEndurance = Workout(
            exercises: [cablePullover],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Muscular Endurance"
        )
        
        // Create workout sequence - includes warmup as part of the sequence
        let upperBodyStrengthSequence = WorkoutSequence(
            workouts: [
                upperBodyCalisthenicsWarmup,
                backFunctionalStrength,
                chestFunctionalStrength,
                chestMuscularEndurance,
                backMuscularEndurance
            ],
            displayName: "Upper Body Strength Workout Sequence",
            activity: .traditionalStrengthTraining,
            location: .indoor
        )
        
        return TrainingSession(
            workoutSequences: [upperBodyStrengthSequence],
            displayName: "Upper Body"
        )
    }

    private func createLowerBodyStrengthTrainingSession() -> TrainingSession {
        // Create exercises
        let cycling = Exercise(displayName: "Cycling", goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let adductors = Exercise(displayName: "Adductors", goal: .open)
        let abductors = Exercise(displayName: "Abductors", goal: .open)
        let backSquats = Exercise(displayName: "Barbell Back Squats", goal: .open)
        let deadlifts = Exercise(displayName: "Barbell Deadlifts", goal: .open)
        let calfRaises = Exercise(displayName: "Single-Leg Calf Raises", goal: .open)
        let lSitHold = Exercise(displayName: "L-Sit Hold", goal: .time(30, .seconds))
        let hangingLegRaises = Exercise(displayName: "Hanging Leg Raises", goal: .time(30, .seconds))
        
        // Create rest periods
        let openRest = Rest()
        let timedRest = Rest(goal: .time(30, .seconds))
        
        // Create workouts
        let cardioWarmupWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            displayName: "Cardio Warmup"
        )
        
        let hipWarmupWorkout = Workout(
            exercises: [adductors, abductors],
            restPeriods: [openRest, openRest],
            iterations: 2,
            displayName: "Hip Warmup"
        )
        
        let frontLowerBodyWorkout = Workout(
            exercises: [backSquats],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Front Lower Body Strength"
        )
        
        let backLowerBodyWorkout = Workout(
            exercises: [deadlifts],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Lower Body Strength"
        )
        
        let stabilityWorkout = Workout(
            exercises: [calfRaises],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Functional Stability"
        )
        
        let coreWorkout = Workout(
            exercises: [lSitHold, hangingLegRaises],
            restPeriods: [timedRest, timedRest],
            iterations: 2,
            displayName: "Core Stability"
        )
        
        // Create workout sequences
        let cardioSequence = WorkoutSequence(
            workouts: [cardioWarmupWorkout],
            displayName: "Cardio Warmup",
            activity: .cycling,
            location: .indoor
        )
        
        let strengthSequence = WorkoutSequence(
            workouts: [hipWarmupWorkout, frontLowerBodyWorkout, backLowerBodyWorkout, stabilityWorkout],
            displayName: "Functional Strength",
            activity: .traditionalStrengthTraining,
            location: .indoor
        )
        
        let coreSequence = WorkoutSequence(
            workouts: [coreWorkout],
            displayName: "Functional Stability",
            activity: .coreTraining,
            location: .indoor
        )
        
        return TrainingSession(
            workoutSequences: [cardioSequence, strengthSequence, coreSequence],
            displayName: "Lower Body Strength"
        )
    }

    private func createLowerBodyEnduranceTrainingSession() -> TrainingSession {
        // Create exercises
        let cycling = Exercise(displayName: "Cycling", goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let continuousRunning = Exercise(displayName: "Continuous Running", goal: .time(1800, .seconds), alert: .speed(10, unit: .kilometersPerHour)) // 10 km/h = 2.78 m/s
        let jumpRope = Exercise(displayName: "Jump Rope", goal: .time(90, .seconds), alert: .heartRate(zone: 4))
        
        // Create rest periods
        let timedRest = Rest(goal: .time(30, .seconds))
        
        // Create workouts
        let cardioWarmupWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            displayName: "Cardio Warmup"
        )
        
        let runningWorkout = Workout(
            exercises: [continuousRunning],
            restPeriods: [],
            displayName: "Paced Run"
        )
        
        let plyometricsWorkout = Workout(
            exercises: [jumpRope],
            restPeriods: [timedRest],
            iterations: 3,
            displayName: "Plyometrics"
        )
        
        // Create workout sequences
        let cardioSequence = WorkoutSequence(
            workouts: [cardioWarmupWorkout],
            displayName: "Cardio Warmup",
            activity: .cycling,
            location: .indoor
        )
        
        let runningSequence = WorkoutSequence(
            workouts: [runningWorkout],
            displayName: "Paced Run",
            activity: .running,
            location: .indoor
        )
        
        let plyometricsSequence = WorkoutSequence(
            workouts: [plyometricsWorkout],
            displayName: "Plyometrics",
            activity: .highIntensityIntervalTraining,
            location: .indoor
        )
        
        return TrainingSession(
            workoutSequences: [cardioSequence, runningSequence, plyometricsSequence],
            displayName: "Lower Body Endurance"
        )
    }

    private func createComplementaryUpperBodyStrengthTrainingSession() -> TrainingSession {
        // Create exercises
        let chinUps = Exercise(displayName: "Chin Ups", goal: .open)
        let dips = Exercise(displayName: "Dips", goal: .open)
        let bicepCurls = Exercise(displayName: "Bicep Curls", goal: .open)
        let tricepsExtension = Exercise(displayName: "Triceps Extension", goal: .open)
        let lateralRaises = Exercise(displayName: "Lateral Raises", goal: .open)
        
        // Create rest periods
        let openRest = Rest()
        
        // Create workouts
        let warmupWorkout = Workout(
            exercises: [chinUps, dips],
            restPeriods: [openRest, openRest],
            iterations: 2,
            displayName: "Complementary Calisthenics Warmup"
        )
        
        let bicepsWorkout = Workout(
            exercises: [bicepCurls],
            restPeriods: [openRest],
            iterations: 2,
            displayName: "Isolated Biceps"
        )
        
        let tricepsWorkout = Workout(
            exercises: [tricepsExtension],
            restPeriods: [openRest],
            iterations: 2,
            displayName: "Isolated Triceps"
        )
        
        let shoulderWorkout = Workout(
            exercises: [lateralRaises],
            restPeriods: [openRest],
            iterations: 2,
            displayName: "Isolated Shoulders"
        )
        
        // Create warmup
        let warmup = Warmup(workouts: [warmupWorkout])
        
        // Create workout sequence
        let mainSequence = WorkoutSequence(
            workouts: [bicepsWorkout, tricepsWorkout, shoulderWorkout],
            displayName: "Complementary Strength",
            activity: .traditionalStrengthTraining,
            location: .indoor
        )
        
        return TrainingSession(
            warmup: warmup,
            workoutSequences: [mainSequence],
            displayName: "Complementary Upper Body Strength"
        )
    }

    private func createFullBodyEnduranceTrainingSession() -> TrainingSession {

        // Create exercises
        let cycling = Exercise(displayName: "Cycling", goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let jumpRope = Exercise(displayName: "Jump Rope", goal: .time(90, .seconds), alert: .heartRate(zone: 4))
        let sprints = Exercise(displayName: "Sprints", goal: .distance(400, .meters), alert: .heartRate(zone: 5))
        
        // Create rest periods
        let timedRest = Rest(goal: .time(30, .seconds))
        let sprintsRest = Rest(goal: .time(30, .seconds))
        
        // Create workouts
        let cardioWarmupWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            displayName: "Cardio Warmup"
        )
        
        let plyometricsWorkout = Workout(
            exercises: [jumpRope],
            restPeriods: [timedRest],
            iterations: 3,
            displayName: "Plyometrics"
        )
        
        let sprintsWorkout = Workout(
            exercises: [sprints],
            restPeriods: [sprintsRest],
            iterations: 3,
            displayName: "Sprints"
        )
        
        // Create workout sequences
        let cardioSequence = WorkoutSequence(
            workouts: [cardioWarmupWorkout],
            displayName: "Cardio Warmup",
            activity: .cycling,
            location: .indoor
        )
        
        let plyometricsSequence = WorkoutSequence(
            workouts: [plyometricsWorkout],
            displayName: "Plyometrics",
            activity: .highIntensityIntervalTraining,
            location: .indoor
        )
        
        let sprintsSequence = WorkoutSequence(
            workouts: [sprintsWorkout],
            displayName: "Sprints",
            activity: .running,
            location: .indoor
        )
        
        return TrainingSession(
            workoutSequences: [cardioSequence, plyometricsSequence, sprintsSequence],
            displayName: "Full Body Endurance"
        )
    }

    private func createFullBodyStrengthTrainingSession() -> TrainingSession {
        // Create exercises
        let pullUps = Exercise(displayName: "Pull Ups", goal: .open)
        let dips = Exercise(displayName: "Dips", goal: .open)
        let latPulldown = Exercise(displayName: "Lat Pulldown", goal: .open)
        let benchPress = Exercise(displayName: "Bench Press", goal: .open)
        let backSquats = Exercise(displayName: "Barbell Back Squats", goal: .open)
        let deadlifts = Exercise(displayName: "Barbell Deadlifts", goal: .open)
        
        // Create rest periods
        let openRest = Rest()
        
        // Create workouts
        let warmupWorkout = Workout(
            exercises: [pullUps, dips],
            restPeriods: [openRest, openRest],
            iterations: 2,
            displayName: "Upper Body Calisthenics Warmup"
        )
        
        let backStrengthWorkout = Workout(
            exercises: [latPulldown],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Functional Strength"
        )
        
        let chestStrengthWorkout = Workout(
            exercises: [benchPress],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Chest Functional Strength"
        )
        
        let frontLowerBodyWorkout = Workout(
            exercises: [backSquats],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Front Lower Body Strength"
        )
        
        let backLowerBodyWorkout = Workout(
            exercises: [deadlifts],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Lower Body Strength"
        )
        
        // Create warmup
        let warmup = Warmup(workouts: [warmupWorkout])
        
        // Create workout sequence
        let mainSequence = WorkoutSequence(
            workouts: [backStrengthWorkout, chestStrengthWorkout, frontLowerBodyWorkout, backLowerBodyWorkout],
            displayName: "Functional Strength",
            activity: .traditionalStrengthTraining,
            location: .indoor
        )
        
        return TrainingSession(
            warmup: warmup,
            workoutSequences: [mainSequence],
            displayName: "Full Body Strength"
        )
    }
}