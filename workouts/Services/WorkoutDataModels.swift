import Foundation
import SwiftData
import WorkoutKit
import HealthKit

@Model
final class PersistentActivitySession {
    var id: UUID = UUID()
    var displayName: String = ""
    var dateCreated: Date = Date()
    var isPrebuilt: Bool = false
    
    @Relationship(deleteRule: .cascade, inverse: \PersistentActivityGroup.session)
    var activityGroups: [PersistentActivityGroup]? = []
    
    init(displayName: String, isPrebuilt: Bool = false) {
        self.id = UUID()
        self.displayName = displayName
        self.dateCreated = Date()
        self.isPrebuilt = isPrebuilt
    }
    
    // Convert to runtime ActivitySession
    func toActivitySession() -> ActivitySession {
        let runtimeGroups = (activityGroups ?? []).sorted { ($0.orderIndex) < ($1.orderIndex) }.map { $0.toActivityGroup() }
        return ActivitySession(activityGroups: runtimeGroups, displayName: displayName)
    }
}

@Model
final class PersistentActivityGroup {
    var orderIndex: Int = 0
    var activityRawValue: UInt = 0
    var locationRawValue: Int = 0
    
    @Relationship(deleteRule: .cascade, inverse: \PersistentWorkout.activityGroup)
    var workouts: [PersistentWorkout]? = []
    
    var session: PersistentActivitySession?
    
    init(activity: HKWorkoutActivityType, location: HKWorkoutSessionLocationType) {
        self.activityRawValue = activity.rawValue
        self.locationRawValue = location.rawValue
    }
    
    var activity: HKWorkoutActivityType {
        get { HKWorkoutActivityType(rawValue: activityRawValue) ?? .other }
        set { activityRawValue = newValue.rawValue }
    }
    
    var location: HKWorkoutSessionLocationType {
        get { HKWorkoutSessionLocationType(rawValue: locationRawValue) ?? .unknown }
        set { locationRawValue = newValue.rawValue }
    }
    
    // Convert to runtime ActivityGroup
    func toActivityGroup() -> ActivityGroup {
        let runtimeWorkouts = (workouts ?? []).sorted { ($0.orderIndex) < ($1.orderIndex) }.map { $0.toWorkout() }
        return ActivityGroup(
            activity: activity,
            location: location,
            workouts: runtimeWorkouts
        )
    }
}

@Model
final class PersistentWorkout {
    var orderIndex: Int = 0
    var iterations: Int = 1
    var workoutTypeRawValue: String?
    
    @Relationship(deleteRule: .cascade, inverse: \PersistentExercise.workout)
    var exercises: [PersistentExercise]? = []
    
    @Relationship(deleteRule: .cascade, inverse: \PersistentRest.workout)
    var restPeriods: [PersistentRest]? = []
    
    var activityGroup: PersistentActivityGroup?
    
    init(iterations: Int = 1, workoutType: WorkoutType? = nil) {
        self.iterations = iterations
        self.workoutTypeRawValue = workoutType?.rawValue
    }
    
    var workoutType: WorkoutType? {
        get { 
            guard let rawValue = workoutTypeRawValue else { return nil }
            return WorkoutType(rawValue: rawValue)
        }
        set { workoutTypeRawValue = newValue?.rawValue }
    }
    
    // Convert to runtime Workout
    func toWorkout() -> Workout {
        let runtimeExercises = (exercises ?? []).map { $0.toExercise() }
        let runtimeRests = (restPeriods ?? []).map { $0.toRest() }
        return Workout(
            exercises: runtimeExercises,
            restPeriods: runtimeRests,
            iterations: iterations,
            workoutType: workoutType
        )
    }
}

@Model
final class PersistentExercise {
    var orderIndex: Int = 0
    var movementRawValue: String = ""
    var goalType: String = "open" // "time", "distance", "open"
    var goalValue: Double = 0
    var goalUnitSymbol: String?
    
    var workout: PersistentWorkout?
    
    init(movement: Movement, goal: WorkoutGoal) {
        self.movementRawValue = movement.rawValue
        
        switch goal {
        case .time(let duration, _):
            self.goalType = "time"
            self.goalValue = duration
            self.goalUnitSymbol = "seconds"
        case .distance(let distance, let unit):
            self.goalType = "distance"
            self.goalValue = distance
            self.goalUnitSymbol = unit.symbol
        case .open:
            self.goalType = "open"
            self.goalValue = 0
            self.goalUnitSymbol = nil
        @unknown default:
            self.goalType = "open"
            self.goalValue = 0
            self.goalUnitSymbol = nil
        }
    }
    
    var movement: Movement {
        get { Movement(rawValue: movementRawValue) ?? .pullUps }
        set { movementRawValue = newValue.rawValue }
    }
    
    var goal: WorkoutGoal {
        switch goalType {
        case "time":
            return .time(goalValue, .seconds)
        case "distance":
            let unit: UnitLength
            switch goalUnitSymbol {
            case "km":
                unit = .kilometers
            case "mi":
                unit = .miles
            default:
                unit = .meters
            }
            return .distance(goalValue, unit)
        default:
            return .open
        }
    }
    
    // Convert to runtime Exercise
    func toExercise() -> Exercise {
        return Exercise(movement: movement, goal: goal)
    }
}

@Model
final class PersistentRest {
    var orderIndex: Int = 0
    var displayName: String = "Rest"
    var goalType: String = "open"
    var goalValue: Double = 0
    var goalUnitSymbol: String?
    
    var workout: PersistentWorkout?
    
    init(displayName: String = "Rest", goal: WorkoutGoal = .open) {
        self.displayName = displayName
        
        switch goal {
        case .time(let duration, _):
            self.goalType = "time"
            self.goalValue = duration
            self.goalUnitSymbol = "seconds"
        case .distance(let distance, let unit):
            self.goalType = "distance"  
            self.goalValue = distance
            self.goalUnitSymbol = unit.symbol
        case .open:
            self.goalType = "open"
            self.goalValue = 0
            self.goalUnitSymbol = nil
        @unknown default:
            self.goalType = "open"
            self.goalValue = 0
            self.goalUnitSymbol = nil
        }
    }
    
    var goal: WorkoutGoal {
        switch goalType {
        case "time":
            return .time(goalValue, .seconds)
        case "distance":
            let unit: UnitLength
            switch goalUnitSymbol {
            case "km":
                unit = .kilometers
            case "mi":
                unit = .miles
            default:
                unit = .meters
            }
            return .distance(goalValue, unit)
        default:
            return .open
        }
    }
    
    // Convert to runtime Rest
    func toRest() -> Rest {
        return Rest(displayName: displayName, goal: goal)
    }
}

// MARK: - Helper Extensions

extension ActivitySession {
    // Convert to persistent model
    func toPersistentModel() -> PersistentActivitySession {
        let persistent = PersistentActivitySession(displayName: displayName, isPrebuilt: false)
        
        for (index, activityGroup) in activityGroups.enumerated() {
            let persistentGroup = activityGroup.toPersistentModel()
            persistentGroup.orderIndex = index
            persistentGroup.session = persistent
            if persistent.activityGroups == nil {
                persistent.activityGroups = []
            }
            persistent.activityGroups?.append(persistentGroup)
        }
        
        return persistent
    }
}

extension ActivityGroup {
    // Convert to persistent model
    func toPersistentModel() -> PersistentActivityGroup {
        let persistent = PersistentActivityGroup(
            activity: activity,
            location: location
        )
        
        for (index, workout) in workouts.enumerated() {
            let persistentWorkout = workout.toPersistentModel()
            persistentWorkout.activityGroup = persistent
            persistentWorkout.orderIndex = index
            if persistent.workouts == nil {
                persistent.workouts = []
            }
            persistent.workouts?.append(persistentWorkout)
        }
        
        return persistent
    }
}

extension Workout {
    // Convert to persistent model
    func toPersistentModel() -> PersistentWorkout {
        let persistent = PersistentWorkout(iterations: iterations, workoutType: workoutType)
        
        for (index, exercise) in exercises.enumerated() {
            let persistentExercise = exercise.toPersistentModel()
            persistentExercise.workout = persistent
            persistentExercise.orderIndex = index
            if persistent.exercises == nil {
                persistent.exercises = []
            }
            persistent.exercises?.append(persistentExercise)
        }
        
        for (index, rest) in restPeriods.enumerated() {
            let persistentRest = rest.toPersistentModel()
            persistentRest.workout = persistent
            persistentRest.orderIndex = index
            if persistent.restPeriods == nil {
                persistent.restPeriods = []
            }
            persistent.restPeriods?.append(persistentRest)
        }
        
        return persistent
    }
}

extension Exercise {
    // Convert to persistent model
    func toPersistentModel() -> PersistentExercise {
        return PersistentExercise(movement: movement, goal: goal)
    }
}

extension Rest {
    // Convert to persistent model
    func toPersistentModel() -> PersistentRest {
        return PersistentRest(displayName: displayName, goal: goal)
    }
} 