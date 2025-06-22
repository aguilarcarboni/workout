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
                
                // Initialize default data if needed
                Task {
                    await DataSeeder.seedDefaultDataIfNeeded(container: container)
                }
                
            } catch {
                print("Failed to configure model container: \(error)")
            }
        }
    }
}
