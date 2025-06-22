import Foundation
import SwiftData
import HealthKit

/// DataSeeder handles the initial seeding of default workout data and checking if it already exists to avoid duplicates.
actor DataSeeder {
    
    /// Seeds default data if none exists
    static func seedDefaultDataIfNeeded(container: ModelContainer) async {
        let context = ModelContext(container)
        
        do {
            // Check if we already have data
            let descriptor = FetchDescriptor<PersistentActivitySession>(
                predicate: #Predicate { $0.isPrebuilt == true }
            )
            let existingSessions = try context.fetch(descriptor)
            
            if existingSessions.isEmpty {
                print("No default data found. Seeding default workouts...")
                await seedDefaultData(context: context)
                try context.save()
                print("Default workout data seeded successfully")
            } else {
                print("Default data already exists (\(existingSessions.count) sessions)")
            }
        } catch {
            print("Error checking/seeding default data: \(error)")
        }
    }
    
    /// Seeds all default workout data
    private static func seedDefaultData(context: ModelContext) async {
        // Create default activity sessions
        let defaultSessions = await createDefaultActivitySessions()
        
        for session in defaultSessions {
            let persistentSession = session.toPersistentModel()
            persistentSession.isPrebuilt = true
            context.insert(persistentSession)
        }
        
        // Create default mind and body sessions
        let mindBodySessions = await createDefaultMindAndBodySessions()
        
        for session in mindBodySessions {
            let persistentSession = session.toPersistentModel()
            persistentSession.isPrebuilt = true
            context.insert(persistentSession)
        }
    }
    
    // MARK: - Default Activity Sessions
    
    private static func createDefaultActivitySessions() async -> [ActivitySession] {
        return [
            createUpperBodyStrengthActivitySession(),
            createLowerBodyStrengthActivitySession(),
            createCardioEnduranceActivitySession()
        ]
    }
    
    private static func createUpperBodyStrengthActivitySession() -> ActivitySession {
        let shortRest = Rest(goal: .time(30, .seconds))
        let openRest = Rest()
        
        let pullUps = Exercise(movement: .pullUps, goal: .open)
        let dips = Exercise(movement: .chestDips, goal: .open)
        let warmupWorkout = Workout(
            exercises: [pullUps, dips],
            restPeriods: [shortRest, shortRest],
            iterations: 2,
            workoutType: .dynamicWarmup
        )
        
        let latPulldown = Exercise(movement: .latPulldowns, goal: .open)
        let backStrengthWorkout = Workout(
            exercises: [latPulldown],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .functionalStrengthWorkout
        )
        
        let benchPress = Exercise(movement: .benchPress, goal: .open)
        let chestStrengthWorkout = Workout(
            exercises: [benchPress],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .functionalStrengthWorkout
        )
        
        let cablePullover = Exercise(movement: .cablePullover, goal: .open)
        let backEnduranceWorkout = Workout(
            exercises: [cablePullover],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .muscularEnduranceWorkout
        )

        let chestFlys = Exercise(movement: .chestFlys, goal: .open)
        let chestEnduranceWorkout = Workout(
            exercises: [chestFlys],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .muscularEnduranceWorkout
        )
        
        return ActivitySession(
            activityGroups: [
                ActivityGroup(activity: .traditionalStrengthTraining, location: .indoor, workouts: [warmupWorkout, backStrengthWorkout, chestStrengthWorkout, chestEnduranceWorkout, backEnduranceWorkout], displayName: "Upper Body")
            ],
            displayName: "Upper Body"
        )
    }

    private static func createLowerBodyStrengthActivitySession() -> ActivitySession {
        let openRest = Rest()
        let timedRest = Rest(goal: .time(30, .seconds))
        
        let cycling = Exercise(movement: .cycling, goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let cardioWarmupWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            workoutType: .warmup
        )
        
        let adductors = Exercise(movement: .adductors, goal: .open)
        let abductors = Exercise(movement: .abductors, goal: .open)
        let hipWarmupWorkout = Workout(
            exercises: [adductors, abductors],
            restPeriods: [openRest, openRest],
            iterations: 2,
            workoutType: .functionalWarmup
        )
        
        let backSquats = Exercise(movement: .barbellBackSquat, goal: .open)
        let squatWorkout = Workout(
            exercises: [backSquats],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .functionalStrengthWorkout
        )
        
        let deadlifts = Exercise(movement: .barbellDeadlifts, goal: .open)
        let deadliftWorkout = Workout(
            exercises: [deadlifts],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .functionalStrengthWorkout
        )
        
        let calfRaises = Exercise(movement: .calfRaises, goal: .open)
        let stabilityWorkout = Workout(
            exercises: [calfRaises],
            restPeriods: [openRest],
            iterations: 3,
            workoutType: .functionalStabilityWorkout
        )
        
        return ActivitySession(
            activityGroups: [
                ActivityGroup(activity: .traditionalStrengthTraining, location: .indoor, workouts: [cardioWarmupWorkout, hipWarmupWorkout, squatWorkout, deadliftWorkout, stabilityWorkout], displayName: "Lower Body")
            ],
            displayName: "Lower Body"
        )
    }

    private static func createCardioEnduranceActivitySession() -> ActivitySession {
        let timedRest = Rest(goal: .time(30, .seconds))
        
        // Cycling warmup and main workout
        let cyclingWarmup = Exercise(movement: .cycling, goal: .time(300, .seconds), alert: .heartRate(zone: 2))
        let cyclingWarmupWorkout = Workout(
            exercises: [cyclingWarmup],
            restPeriods: [],
            workoutType: .warmup
        )
        
        let cycling = Exercise(movement: .cycling, goal: .time(900, .seconds), alert: .heartRate(zone: 3))
        let cyclingWorkout = Workout(
            exercises: [cycling],
            restPeriods: [],
            workoutType: .aerobicEnduranceWorkout
        )
        
        // Running main workout
        let continuousRunning = Exercise(movement: .run, goal: .time(1800, .seconds), alert: .speed(10, unit: .kilometersPerHour))
        let runningWorkout = Workout(
            exercises: [continuousRunning],
            restPeriods: [],
            workoutType: .aerobicEnduranceWorkout
        )
        
        // Jump rope HIIT workout
        let jumpRope = Exercise(movement: .jumpRope, goal: .time(90, .seconds), alert: .heartRate(zone: 4))
        let plyometricsWorkout = Workout(
            exercises: [jumpRope],
            restPeriods: [timedRest],
            iterations: 3,
            workoutType: .anaerobicEnduranceWorkout
        )
        
        return ActivitySession(
            activityGroups: [
                ActivityGroup(activity: .cycling, location: .indoor, workouts: [cyclingWarmupWorkout, cyclingWorkout], displayName: "Cycling"),
                ActivityGroup(activity: .running, location: .indoor, workouts: [runningWorkout], displayName: "Running"),
                ActivityGroup(activity: .jumpRope, location: .indoor, workouts: [plyometricsWorkout], displayName: "HIIT")
            ],
            displayName: "Mixed Cardio"
        )
    }
    
    // MARK: - Default Mind and Body Sessions
    
    private static func createDefaultMindAndBodySessions() async -> [ActivitySession] {
        return [
            createYogaFlowSession()
        ]
    }
    
    private static func createYogaFlowSession() -> ActivitySession {
        let shortRest = Rest(goal: .time(10, .seconds))
        let transitionRest = Rest(goal: .time(5, .seconds))
        
        // Warm-up flow
        let mountainPose = Exercise(movement: .mountainPose, goal: .time(30, .seconds))
        let catCow = Exercise(movement: .catCowPose, goal: .time(60, .seconds))
        let childsPose = Exercise(movement: .childsPose, goal: .time(30, .seconds))
        let warmupWorkout = Workout(
            exercises: [mountainPose, catCow, childsPose],
            restPeriods: [transitionRest, transitionRest, shortRest],
            workoutType: .warmup
        )
        
        // Main flow
        let sunSalutation = Exercise(movement: .sunSalutation, goal: .time(300, .seconds))
        let warrior1 = Exercise(movement: .warriorOne, goal: .time(45, .seconds))
        let warrior2 = Exercise(movement: .warriorTwo, goal: .time(45, .seconds))
        let triangle = Exercise(movement: .trianglePose, goal: .time(45, .seconds))
        let mainFlowWorkout = Workout(
            exercises: [sunSalutation, warrior1, warrior2, triangle],
            restPeriods: [shortRest, transitionRest, transitionRest, shortRest],
            iterations: 2
        )
        
        // Cool-down
        let downwardDog = Exercise(movement: .downwardDog, goal: .time(60, .seconds))
        let cobra = Exercise(movement: .cobralPose, goal: .time(45, .seconds))
        let finalChildsPose = Exercise(movement: .childsPose, goal: .time(120, .seconds))
        let cooldownWorkout = Workout(
            exercises: [downwardDog, cobra, finalChildsPose],
            restPeriods: [transitionRest, transitionRest, Rest()],
            workoutType: .cooldown
        )
        
        return ActivitySession(
            activityGroups: [
                ActivityGroup(activity: .yoga, location: .indoor, workouts: [warmupWorkout, mainFlowWorkout, cooldownWorkout], displayName: "Yoga Flow")
            ],
            displayName: "Yoga Flow"
        )
    }
} 