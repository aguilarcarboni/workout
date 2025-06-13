import Foundation
import WorkoutKit
import HealthKit

// MARK: - Core Enums

/**
 * FitnessMetric: The different aspects of fitness that can be improved
 */
enum FitnessMetric: String, CaseIterable {
    case strength = "Strength"
    case stability = "Stability"
    case speed = "Speed"
    case endurance = "Endurance"
    case aerobicEndurance = "Aerobic Endurance"
    case anaerobicEndurance = "Anaerobic Endurance"
    case muscularEndurance = "Muscular Endurance"
    case agility = "Agility"
    case power = "Power"
    case mobility = "Mobility"
}

/**
 * Muscle: The different muscle groups and body parts that can be targeted
 */
enum Muscle: String, CaseIterable {
    // Core muscles
    case core = "Core"
    case obliques = "Obliques"
    case psoas = "Psoas"
    case iliacus = "Iliacus"
    
    // Upper body
    case chest = "Chest"
    case back = "Back"
    case lats = "Lats"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    
    // Lower body
    case quadriceps = "Quadriceps"
    case hamstrings = "Hamstrings"
    case glutes = "Glutes"
    case calves = "Calves"
    case adductors = "Adductors"
    case abductors = "Abductors"
    
    // Full body
    case fullBody = "Full Body"
}

/**
 * Movement: The physical movements that can be performed
 */
enum Movement: String, CaseIterable {
    // Upper body movements
    case pullUps = "Pull Ups"
    case chinUps = "Chin Ups"
    case chestDips = "Chest Dips"
    case tricepDips = "Tricep Dips"
    case benchPress = "Bench Press"
    case latPulldowns = "Lat Pulldowns"
    case cablePullover = "Cable Pullover"
    case chestFlys = "Chest Flys"
    case bicepCurls = "Bicep Curls"
    case hammerCurls = "Hammer Curls"
    case preacherCurls = "Preacher Curls"
    case lateralRaises = "Lateral Raises"
    case overheadPress = "Overhead Press"
    case facePulls = "Face Pulls"
    case tricepPulldown = "Tricep Pulldown"
    case overheadPull = "Overhead Pull"
    
    // Lower body movements
    case barbellBackSquat = "Barbell Back Squat"
    case barbellDeadlifts = "Barbell Deadlifts"
    case calfRaises = "Calf Raises"
    case adductors = "Adductors"
    case abductors = "Abductors"
    
    // Core movements
    case lSit = "L-Sit"
    case legRaise = "Leg Raise"
    
    // Cardio movements
    case cycling = "Cycling"
    case run = "Run"
    case sprint = "Sprint"
    case jumpRope = "Jump Rope"
    
    // Stretching movements
    case benchHipFlexorStretch = "Bench Hip Flexor Stretch"
    
    // Complex movements
    case bearCrawls = "Bear Crawls"
    case hingeToSquat = "Hinge to Squat"
    case pikePulse = "Pike Pulse"
    case precisionBroadJump = "Precision Broad Jump"
    case ropeClimbing = "Rope Climbing"
    
    /**
     * Returns the primary muscles targeted by this movement
     */
    var targetMuscles: [Muscle] {
        switch self {
        // Upper body
        case .pullUps, .chinUps, .latPulldowns, .cablePullover:
            return [.back, .lats, .biceps]
        case .chestDips, .benchPress, .chestFlys:
            return [.chest, .triceps]
        case .tricepDips, .tricepPulldown, .overheadPull:
            return [.triceps]
        case .bicepCurls, .hammerCurls, .preacherCurls:
            return [.biceps]
        case .lateralRaises, .overheadPress, .facePulls:
            return [.shoulders]
            
        // Lower body
        case .barbellBackSquat:
            return [.quadriceps, .glutes]
        case .barbellDeadlifts:
            return [.hamstrings, .glutes, .back]
        case .calfRaises:
            return [.calves]
        case .adductors:
            return [.adductors]
        case .abductors:
            return [.abductors]
            
        // Core
        case .lSit, .legRaise:
            return [.core, .psoas]
            
        // Cardio (full body engagement)
        case .cycling, .run, .sprint, .jumpRope:
            return [.fullBody]
            
        // Stretching
        case .benchHipFlexorStretch:
            return [.psoas, .iliacus]
            
        // Complex movements
        case .bearCrawls, .pikePulse:
            return [.core, .psoas]
        case .hingeToSquat:
            return [.fullBody]
        case .precisionBroadJump:
            return [.fullBody]
        case .ropeClimbing:
            return [.fullBody]
        }
    }
}

/**
 * WorkoutType: Different categories/types of workouts
 */
enum WorkoutType: String, CaseIterable {
    // Basic types
    case warmup = "Warmup"
    case cooldown = "Cooldown"
    case strengthWorkout = "Strength Workout"
    case enduranceWorkout = "Endurance Workout"
    case stabilityWorkout = "Stability Workout"
    
    // Specific warmup types
    case dynamicWarmup = "Dynamic Warmup"
    case functionalWarmup = "Functional Warmup"
    
    // Specific strength types
    case functionalStrengthWorkout = "Functional Strength Workout"
    
    // Specific endurance types
    case muscularEnduranceWorkout = "Muscular Endurance Workout"
    case aerobicEnduranceWorkout = "Aerobic Endurance Workout"
    case anaerobicEnduranceWorkout = "Anaerobic Endurance Workout"
    
    // Specific stability types
    case functionalStabilityWorkout = "Functional Stability Workout"
    
    /**
     * Returns the primary fitness metrics this workout type develops
     */
    var targetMetrics: [FitnessMetric] {
        switch self {
        case .warmup, .dynamicWarmup:
            return [.mobility, .stability]
        case .functionalWarmup:
            return [.mobility, .stability, .strength, .power]
        case .cooldown:
            return [.mobility]
        case .strengthWorkout:
            return [.strength]
        case .functionalStrengthWorkout:
            return [.strength, .mobility, .stability, .power]
        case .enduranceWorkout:
            return [.endurance]
        case .muscularEnduranceWorkout:
            return [.muscularEndurance, .stability, .mobility]
        case .aerobicEnduranceWorkout:
            return [.aerobicEndurance, .speed, .strength, .power]
        case .anaerobicEnduranceWorkout:
            return [.anaerobicEndurance, .speed, .strength, .power]
        case .stabilityWorkout:
            return [.stability]
        case .functionalStabilityWorkout:
            return [.stability, .strength, .endurance, .power]
        }
    }
}

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
 * - Now includes movement and target muscles
 */
class Exercise: TrackableComponent, WorkoutKitConvertible {
    typealias WorkoutKitType = IntervalStep
    
    let goal: WorkoutGoal
    let alert: (any WorkoutAlert)?
    let movement: Movement
    let targetMuscles: [Muscle]
    
    var displayName: String {
        return movement.rawValue
    }
    
    init(movement: Movement, goal: WorkoutGoal, alert: (any WorkoutAlert)? = nil) {
        self.movement = movement
        self.goal = goal
        self.alert = alert
        self.targetMuscles = movement.targetMuscles
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
 * - Now includes workout type and target fitness metrics
 */
class Workout: RepeatableComponent, WorkoutKitConvertible {
    typealias WorkoutKitType = IntervalBlock
    
    let exercises: [Exercise]
    let restPeriods: [Rest]
    let iterations: Int
    let displayName: String
    let workoutType: WorkoutType?
    let targetMetrics: [FitnessMetric]
    
    init(exercises: [Exercise], restPeriods: [Rest], iterations: Int = 1, displayName: String, workoutType: WorkoutType? = nil) {
        self.exercises = exercises
        self.restPeriods = restPeriods
        self.iterations = iterations
        self.displayName = displayName
        self.workoutType = workoutType
        self.targetMetrics = workoutType?.targetMetrics ?? []
    }
    
    /// Returns all muscles targeted by this workout
    var targetMuscles: [Muscle] {
        let allMuscles = exercises.flatMap { $0.targetMuscles }
        return Array(Set(allMuscles)) // Remove duplicates
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
    
    /// Returns a detailed plain text description of the workout
    func printableDescription() -> String {
        var output = ""
        
        output += "\(displayName)"
        if let workoutType = workoutType {
            output += " (\(workoutType.rawValue))"
        }
        output += "\n"
        
        // Show iterations
        if iterations > 1 {
            output += "   Sets: \(iterations)\n"
        }
        
        // Show target metrics
        if !targetMetrics.isEmpty {
            output += "   Target Metrics: \(targetMetrics.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        // Show target muscles
        if !targetMuscles.isEmpty {
            output += "   Target Muscles: \(targetMuscles.map { $0.rawValue }.joined(separator: ", "))\n"
        }
        
        // Show exercises and rest periods
        output += "   Exercises:\n"
        for (index, exercise) in exercises.enumerated() {
            output += "     • \(exercise.displayName)"
            
            // Show goal
            switch exercise.goal {
            case .time(let duration, _):
                let minutes = Int(duration) / 60
                let seconds = Int(duration) % 60
                output += " - Goal: \(String(format: "%02d:%02d", minutes, seconds))"
            case .distance(let distance, let unit):
                output += " - Goal: \(String(format: "%.1f %@", distance, unit.symbol))"
            case .open:
                output += " - Goal: Open"
            @unknown default:
                output += " - Goal: Unknown"
            }
            
            // Show alert if any
            if let alert = exercise.alert {
                output += " - Alert: \(alertDescription(alert))"
            }
            
            output += "\n"
            
            // Add rest period if available
            if index < restPeriods.count {
                let rest = restPeriods[index]
                output += "       Rest: \(rest.displayName)"
                switch rest.goal {
                case .time(let duration, _):
                    let minutes = Int(duration) / 60
                    let seconds = Int(duration) % 60
                    output += " (\(String(format: "%02d:%02d", minutes, seconds)))"
                case .open:
                    output += " (Open)"
                default:
                    break
                }
                output += "\n"
            }
        }
        
        return output
    }
    
    /// Helper function to describe workout alerts
    private func alertDescription(_ alert: any WorkoutAlert) -> String {
        switch alert {
        case let heartRateAlert as HeartRateRangeAlert:
            let lowerBound = heartRateAlert.target.lowerBound.value
            let upperBound = heartRateAlert.target.upperBound.value
            return "HR \(Int(lowerBound))-\(Int(upperBound)) BPM"
        case let heartRateAlert as HeartRateZoneAlert:
            return "HR Zone \(heartRateAlert.zone)"
        case let powerAlert as PowerRangeAlert:
            let lowerBound = powerAlert.target.lowerBound.value
            let upperBound = powerAlert.target.upperBound.value
            return "Power \(Int(lowerBound))-\(Int(upperBound)) W"
        case let powerAlert as PowerThresholdAlert:
            return "Power \(Int(powerAlert.target.value)) W"
        case let powerAlert as PowerZoneAlert:
            return "Power Zone \(powerAlert.zone)"
        case let cadenceAlert as CadenceRangeAlert:
            let lowerBound = cadenceAlert.target.lowerBound.value
            let upperBound = cadenceAlert.target.upperBound.value
            return "Cadence \(Int(lowerBound))-\(Int(upperBound)) RPM"
        case let cadenceAlert as CadenceThresholdAlert:
            return "Cadence \(Int(cadenceAlert.target.value)) RPM"
        case let speedAlert as SpeedRangeAlert:
            let lowerBound = speedAlert.target.lowerBound.value
            let upperBound = speedAlert.target.upperBound.value
            return "Speed \(String(format: "%.1f", lowerBound))-\(String(format: "%.1f", upperBound)) \(speedAlert.target.lowerBound.unit.symbol)"
        case let speedAlert as SpeedThresholdAlert:
            return "Speed \(String(format: "%.1f", speedAlert.target.value)) \(speedAlert.target.unit.symbol)"
        default:
            return "Target Alert"
        }
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
    
    /// Returns a detailed plain text description of the entire training session
    func printableDescription() -> String {
        var output = ""
        
        output += "=== \(displayName.uppercased()) ===\n\n"
        
        // Warmup Section
        if let warmup = warmup, !warmup.workouts.isEmpty {
            output += "🔥 WARMUP\n"
            output += "--------\n"
            for (index, workout) in warmup.workouts.enumerated() {
                output += "\(index + 1). \(workout.printableDescription())\n"
            }
            output += "\n"
        }
        
        // Main Workout Sequences
        output += "💪 MAIN WORKOUTS\n"
        output += "---------------\n"
        for (sequenceIndex, sequence) in workoutSequences.enumerated() {
            output += "\nSequence \(sequenceIndex + 1): \(sequence.displayName)\n"
            output += "Activity: \(sequence.activity.displayName)\n"
            output += "Location: \(sequence.location.displayName)\n\n"
            
            for (workoutIndex, workout) in sequence.workouts.enumerated() {
                output += "  \(workoutIndex + 1). \(workout.printableDescription())\n"
            }
        }
        
        // Cooldown Section
        if let cooldown = cooldown, !cooldown.workouts.isEmpty {
            output += "\n❄️ COOLDOWN\n"
            output += "----------\n"
            for (index, workout) in cooldown.workouts.enumerated() {
                output += "\(index + 1). \(workout.printableDescription())\n"
            }
        }
        
        return output
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
    
    @Published var trainingSessions: [TrainingSession] = []
    
    func createWorkouts() async {
        let sessions = await createPredefinedTrainingSessions()
        
        await MainActor.run {
            self.trainingSessions = sessions
        }
    }
    
    private func createPredefinedTrainingSessions() async -> [TrainingSession] {
        return [
            createUpperBodyStrengthTrainingSession(),
            createLowerBodyStrengthTrainingSession(),
            createLowerBodyEnduranceTrainingSession(),
        ]
    }
    
    private func createUpperBodyStrengthTrainingSession() -> TrainingSession {

        let shortRest = Rest(goal: .time(30, .seconds))
        let openRest = Rest()
        
        let pullUps = Exercise(movement: .pullUps, goal: .open)
        let dips = Exercise(movement: .chestDips, goal: .open)
        let upperBodyCalisthenicsWarmup = Workout(
            exercises: [pullUps, dips],
            restPeriods: [shortRest, shortRest],
            iterations: 2,
            displayName: "Calisthenics Warmup",
            workoutType: .functionalWarmup
        )
        
        let latPulldown = Exercise(movement: .latPulldowns, goal: .open)
        let backFunctionalStrength = Workout(
            exercises: [latPulldown],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Functional Strength",
            workoutType: .functionalStrengthWorkout
        )
        
        let benchPress = Exercise(movement: .benchPress, goal: .open)
        let chestFunctionalStrength = Workout(
            exercises: [benchPress],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Chest Functional Strength",
            workoutType: .functionalStrengthWorkout
        )
        
        let cablePullover = Exercise(movement: .cablePullover, goal: .open)
        let backMuscularEndurance = Workout(
            exercises: [cablePullover],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Muscular Endurance",
            workoutType: .muscularEnduranceWorkout
        )

        let chestFlys = Exercise(movement: .chestFlys, goal: .open)
        let chestMuscularEndurance = Workout(
            exercises: [chestFlys],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Chest Muscular Endurance",
            workoutType: .muscularEnduranceWorkout
        )
        
        let upperBodyStrengthSequence = WorkoutSequence(
            workouts: [
                upperBodyCalisthenicsWarmup,
                backFunctionalStrength,
                chestFunctionalStrength,
                chestMuscularEndurance,
                backMuscularEndurance
            ],
            displayName: "Functional Strength",
            activity: .traditionalStrengthTraining,
            location: .indoor
        )
        
        return TrainingSession(
            workoutSequences: [upperBodyStrengthSequence],
            displayName: "Upper Body"
        )
    }

    private func createLowerBodyStrengthTrainingSession() -> TrainingSession {
        
        let openRest = Rest()
        let timedRest = Rest(goal: .time(30, .seconds))
        
        let cycling = Exercise(movement: .cycling, goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let cardioWarmupWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            displayName: "Cardio Warmup",
            workoutType: .functionalWarmup
        )
        
        let adductors = Exercise(movement: .adductors, goal: .open)
        let abductors = Exercise(movement: .abductors, goal: .open)
        let hipWarmupWorkout = Workout(
            exercises: [adductors, abductors],
            restPeriods: [openRest, openRest],
            iterations: 2,
            displayName: "Hip Warmup",
            workoutType: .functionalWarmup
        )
        
        let backSquats = Exercise(movement: .barbellBackSquat, goal: .open)
        let frontLowerBodyWorkout = Workout(
            exercises: [backSquats],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Front Lower Body Strength",
            workoutType: .functionalStrengthWorkout
        )
        
        let deadlifts = Exercise(movement: .barbellDeadlifts, goal: .open)
        let backLowerBodyWorkout = Workout(
            exercises: [deadlifts],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Back Lower Body Strength",
            workoutType: .functionalStrengthWorkout
        )
        
        let calfRaises = Exercise(movement: .calfRaises, goal: .open)
        let stabilityWorkout = Workout(
            exercises: [calfRaises],
            restPeriods: [openRest],
            iterations: 3,
            displayName: "Functional Stability",
            workoutType: .functionalStabilityWorkout
        )
        
        let lSitHold = Exercise(movement: .lSit, goal: .time(30, .seconds))
        let hangingLegRaises = Exercise(movement: .legRaise, goal: .time(30, .seconds))
        let coreWorkout = Workout(
            exercises: [lSitHold, hangingLegRaises],
            restPeriods: [timedRest, timedRest],
            iterations: 2,
            displayName: "Core Stability",
            workoutType: .functionalStabilityWorkout
        )
        
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

        let timedRest = Rest(goal: .time(30, .seconds))
        
        let cycling = Exercise(movement: .cycling, goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let cardioWarmupWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            displayName: "Cardio Warmup",
            workoutType: .functionalWarmup
        )
        
        let continuousRunning = Exercise(movement: .run, goal: .time(1800, .seconds), alert: .speed(10, unit: .kilometersPerHour)) // 10 km/h = 2.78 m/s
        let runningWorkout = Workout(
            exercises: [continuousRunning],
            restPeriods: [],
            displayName: "Paced Run",
            workoutType: .aerobicEnduranceWorkout
        )
        
        let jumpRope = Exercise(movement: .jumpRope, goal: .time(90, .seconds), alert: .heartRate(zone: 4))
        let plyometricsWorkout = Workout(
            exercises: [jumpRope],
            restPeriods: [timedRest],
            iterations: 3,
            displayName: "Plyometrics",
            workoutType: .anaerobicEnduranceWorkout
        )
        
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
}
