//
//  WorkoutExtension.swift
//  workouts
//
//  Created by Andrés on 21/5/2025.
//

import Foundation
import WorkoutKit
import HealthKit

extension HKWorkoutActivityType {
    var name: String {
        switch self {
        case .running:
            return "Running"
        case .cycling:
            return "Cycling"
        case .walking:
            return "Walking"
        case .swimming:
            return "Swimming"
        case .hiking:
            return "Hiking"
        case .yoga:
            return "Yoga"
        case .traditionalStrengthTraining:
            return "Traditional Strength Training"
        default:
            return "Workout"
        }
    }
}

extension HKWorkout: Identifiable {
    public var id: UUID {
        uuid
    }
}
