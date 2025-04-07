//
//  workoutsApp.swift
//  workouts
//
//  Created by Andrés on 5/4/2025.
//

import SwiftUI
import HealthKit

// Health manager class to handle HealthKit operations
class HealthManager {
    static let shared = HealthManager()
    
    func requestAuthorization() async {
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
}

@main
struct workoutsApp: App {
    @State private var isHealthKitAuthorized = false
    
    init() {
        // Add usage descriptions programmatically if needed
        print("App initialized - HealthKit and WorkoutKit setup")
        
        #if os(watchOS)
        // Initialize watch-specific setup
        #else
        // Request authorization on app launch for iOS
        Task {
            await HealthManager.shared.requestAuthorization()
        }
        #endif
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    #if !os(watchOS)
                    Task {
                        await HealthManager.shared.requestAuthorization()
                    }
                    #endif
                }
        }
    }
}
