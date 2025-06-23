//
//  workoutsApp.swift
//  workouts
//
//  Created by Andrés on 5/4/2025.
//

import SwiftUI
import SwiftData
import WorkoutKit

@main
struct workoutsApp: App {
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [
            PersistentActivitySession.self,
            PersistentActivityGroup.self,
            PersistentWorkout.self,
            PersistentExercise.self,
            PersistentRest.self
        ]) { result in
            do {
                let container = try result.get()
                
                // Configure for CloudKit
                let schema = Schema([
                    PersistentActivitySession.self,
                    PersistentActivityGroup.self,
                    PersistentWorkout.self,
                    PersistentExercise.self,
                    PersistentRest.self
                ])
                
                let modelConfiguration = ModelConfiguration(
                    schema: schema,
                    isStoredInMemoryOnly: false,
                    cloudKitDatabase: .automatic
                )
                
                // Initialize app startup sequence
                Task {
                    await initializeApp(container: container)
                }
                
            } catch {
                print("Failed to configure model container: \(error)")
            }
        }
    }
    
    /// Complete app initialization sequence:
    /// 1. Authenticate all services
    /// 2. Remove all scheduled workouts
    /// 3. Load sessions from CloudKit making sure default data exists
    private func initializeApp(container: ModelContainer) async {
        print("🚀 Starting app initialization...")
        
        // Step 1: Authenticate all services
        await authenticateServices()
        
        // Step 2: Remove all scheduled workouts
        await cleanupScheduledWorkouts()
        
        // Step 3: Load sessions from CloudKit making sure default data exists
        await loadWorkoutSessions(container: container)
        
        print("✅ App initialization complete")
    }
    
    /// Step 1: Authenticate all required services
    private func authenticateServices() async {
        print("🔐 Authenticating services...")
        
        let workoutScheduler = WorkoutScheduler.shared
        let notificationManager = NotificationManager.shared
        
        // Authenticate WorkoutScheduler (WorkoutKit)
        let workoutAuthStatus = await workoutScheduler.requestAuthorization()
        print("   WorkoutScheduler authorization: \(workoutAuthStatus)")
        
        // Authenticate NotificationManager (UserNotifications)
        let notificationAuthStatus = await notificationManager.requestAuthorization()
        print("   NotificationManager authorization: \(notificationAuthStatus)")
    }
    
    /// Step 2: Remove all scheduled workouts that are before today
    private func cleanupScheduledWorkouts() async {
        print("🧹 Cleaning up scheduled workouts...")
        
        let workoutScheduler = WorkoutScheduler.shared
        let scheduledWorkouts = await workoutScheduler.scheduledWorkouts
        let yesterday: Date = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        let calendar = Calendar.current
        
        var removedCount = 0
        for scheduledWorkout in scheduledWorkouts {
            if let scheduledDate = calendar.date(from: scheduledWorkout.date), scheduledDate < yesterday {
                await workoutScheduler.remove(scheduledWorkout.plan, at: scheduledWorkout.date)
                removedCount += 1
            }
        }
        
        print("   Removed \(removedCount) old scheduled workouts")
    }
    
    /// Step 3: Load workout sessions from CloudKit, creating defaults if none exist
    private func loadWorkoutSessions(container: ModelContainer) async {
        print("💾 Loading workout sessions from CloudKit...")
        
        let context = ModelContext(container)
        let workoutManager = WorkoutManager.shared
        
        // This will automatically create default sessions if none exist
        // and load from CloudKit if they do exist
        workoutManager.loadSessions(from: context)
        
        print("   Sessions loaded: \(workoutManager.activitySessions.count) workout sessions, \(workoutManager.mindAndBodySessions.count) mind & body sessions")
    }
}


