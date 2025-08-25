import Foundation
import WorkoutKit
import HealthKit
import SwiftUI

// WorkoutKit
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
        case .coreTraining:
            return "Core Training"
        case .mindAndBody:
            return "Mind and Body"
        case .soccer:
            return "Outdoor Soccer"
        case .traditionalStrengthTraining:
            return "Traditional Strength Training"
        case .functionalStrengthTraining:
            return "Functional Strength Training"
        case .crossTraining:
            return "Cross Training"
        case .mixedCardio:
            return "Mixed Cardio"
        case .highIntensityIntervalTraining:
            return "High Intensity Interval Training"
        case .jumpRope:
            return "Jump Rope"
        case .flexibility:
            return "Flexibility"
        default:
            return "Workout"
        }
    }
    
    var displayName: String {
        return name
    }
}

extension HKWorkoutActivityType {
    var icon: String {
        switch self {
        case .archery: return "figure.archery"
        case .bowling: return "figure.bowling"
        case .fencing: return "figure.fencing"
        case .gymnastics: return "figure.gymnastics"
        case .trackAndField: return "figure.track.and.field"
        case .americanFootball: return "figure.american.football"
        case .australianFootball: return "figure.australian.football"
        case .baseball: return "figure.baseball"
        case .basketball: return "figure.basketball"
        case .cricket: return "figure.cricket"
        case .discSports: return "figure.disc.sports"
        case .handball: return "figure.handball"
        case .hockey: return "figure.hockey"
        case .lacrosse: return "figure.lacrosse"
        case .rugby: return "figure.rugby"
        case .soccer: return "figure.outdoor.soccer"
        case .softball: return "figure.softball"
        case .volleyball: return "figure.volleyball"
        case .preparationAndRecovery: return "figure.cooldown"
        case .flexibility: return "figure.flexibility"
        case .cooldown: return "figure.cooldown"
        case .walking: return "figure.walk"
        case .running: return "figure.run"
        case .wheelchairWalkPace: return "figure.roll"
        case .wheelchairRunPace: return "figure.roll.runningpace"
        case .cycling: return "figure.outdoor.cycle"
        case .handCycling: return "figure.hand.cycling"
        case .coreTraining: return "figure.core.training"
        case .elliptical: return "figure.elliptical"
        case .functionalStrengthTraining: return "figure.strengthtraining.functional"
        case .traditionalStrengthTraining: return "figure.strengthtraining.traditional"
        case .crossTraining: return "figure.cross.training"
        case .mixedCardio: return "figure.mixed.cardio"
        case .highIntensityIntervalTraining: return "figure.highintensity.intervaltraining"
        case .jumpRope: return "figure.jumprope"
        case .stairClimbing: return "figure.stair.stepper"
        case .stairs: return "figure.stairs"
        case .stepTraining: return "figure.step.training"
        case .fitnessGaming: return "gamecontroller"
        case .barre: return "figure.barre"
        case .cardioDance: return "figure.dance"
        case .socialDance: return "figure.socialdance"
        case .yoga: return "figure.yoga"
        case .mindAndBody: return "figure.mind.and.body"
        case .pilates: return "figure.pilates"
        case .badminton: return "figure.badminton"
        case .pickleball: return "figure.pickleball"
        case .racquetball: return "figure.racquetball"
        case .squash: return "figure.squash"
        case .tableTennis: return "figure.table.tennis"
        case .tennis: return "figure.tennis"
        case .climbing: return "figure.climbing"
        case .equestrianSports: return "figure.equestrian.sports"
        case .fishing: return "figure.fishing"
        case .golf: return "figure.golf"
        case .hiking: return "figure.hiking"
        case .hunting: return "figure.hunting"
        case .play: return "figure.play"
        case .crossCountrySkiing: return "figure.skiing.crosscountry"
        case .curling: return "figure.curling"
        case .downhillSkiing: return "figure.skiing.downhill"
        case .snowSports: return "figure.snowboarding"
        case .snowboarding: return "figure.snowboarding"
        case .skatingSports: return "figure.ice.skating"
        case .paddleSports: return "figure.surfing"
        case .rowing: return "figure.indoor.rowing"
        case .sailing: return "figure.sailing"
        case .surfingSports: return "figure.surfing"
        case .swimming: return "figure.pool.swim"
        case .waterFitness: return "figure.water.fitness"
        case .waterPolo: return "figure.waterpolo"
        case .waterSports: return "figure.water.fitness"
        case .boxing: return "figure.boxing"
        case .kickboxing: return "figure.kickboxing"
        case .martialArts: return "figure.martial.arts"
        case .taiChi: return "figure.taichi"
        case .wrestling: return "figure.wrestling"
        case .swimBikeRun: return "figure.cross.training"
        case .transition: return "arrow.triangle.2.circlepath"
        case .underwaterDiving: return "figure.pool.swim"
        case .other: return "figure.walk"
        default: return "figure.walk"
        }
    }
}

extension HKWorkoutSessionLocationType {
    var displayName: String {
        switch self {
        case .indoor:
            return "Indoor"
        case .outdoor:
            return "Outdoor"
        case .unknown:
            return "Unknown"
        @unknown default:
            return "Unknown"
        }
    }
    
    var icon: String {
        switch self {
        case .indoor:
            return "house.fill"
        case .outdoor:
            return "tree.fill"
        case .unknown:
            return "questionmark.circle"
        @unknown default:
            return "questionmark.circle"
        }
    }
}

extension HKWorkout: @retroactive Identifiable {
    public var id: UUID {
        uuid
    }
}

extension HKWorkout {
    /// Active energy in kilocalories burned during the workout, if available.
    var activeCalories: Double? {
        if #available(iOS 18.0, *) {
            return statistics(for: HKQuantityType(.activeEnergyBurned))?.sumQuantity()?.doubleValue(for: .kilocalorie())
        } else {
            return totalEnergyBurned?.doubleValue(for: .kilocalorie())
        }
    }

    /// Simple estimate of total calories (active + 30 kcal overhead).
    /// Replace the additional constant with a more accurate calculation if available.
    var totalCaloriesEstimate: Double? {
        guard let active = activeCalories else { return nil }
        return active + 30
    }
}

// Custom Types

extension FitnessMetric {
    /// Defines a canonical visual ordering for fitness metrics when displayed in the UI.
    static let uiDisplayOrder: [FitnessMetric] = [
        .strength,
        .power,
        .speed,
        .endurance,
        .aerobicEndurance,
        .anaerobicEndurance,
        .muscularEndurance,
        .stability,
        .mobility,
        .agility
    ]

    /// Comparison helper suitable for `sorted(by:)`.
    static func defaultOrder(_ lhs: FitnessMetric, _ rhs: FitnessMetric) -> Bool {
        let lhsIndex = uiDisplayOrder.firstIndex(of: lhs) ?? uiDisplayOrder.count
        let rhsIndex = uiDisplayOrder.firstIndex(of: rhs) ?? uiDisplayOrder.count
        return lhsIndex < rhsIndex
    }
}

extension Workout {
    /// Returns the Exercise corresponding to a given IntervalStep index produced by `toWorkoutKitType()`.
    /// Assumes exercises and rest periods alternate (work, rest, work, rest, ...).
    func exerciseForStepIndex(_ stepIndex: Int) -> Exercise? {
        let exerciseIndex = stepIndex / 2
        if stepIndex % 2 == 0 && exerciseIndex < exercises.count {
            return exercises[exerciseIndex]
        }
        return nil
    }
}

extension WorkoutGoal {
    /// Human-readable description for display purposes.
    var description: String {
        switch self {
        case .time(let duration, _):
            return formatDuration(duration)
        case .distance(let distance, let unit):
            return String(format: "%.1f %@", distance, unit.symbol)
        case .open:
            return "No goal"
        @unknown default:
            return "Unknown goal"
        }
    }
}

public extension WorkoutAlert {
    /// System SF-Symbol representing the alert.
    var iconName: String {
        switch self {
        case is HeartRateRangeAlert, is HeartRateZoneAlert:
            return "heart.fill"
        case is PowerRangeAlert, is PowerThresholdAlert, is PowerZoneAlert:
            return "bolt.fill"
        case is CadenceRangeAlert, is CadenceThresholdAlert:
            return "figure.run"
        case is SpeedRangeAlert, is SpeedThresholdAlert:
            return "speedometer"
        default:
            return "bell.fill"
        }
    }

    /// Tint colour associated with the alert type.
    var tintColor: Color {
        switch self {
        case is HeartRateRangeAlert, is HeartRateZoneAlert:
            return .red
        case is PowerRangeAlert, is PowerThresholdAlert, is PowerZoneAlert:
            return .orange
        case is CadenceRangeAlert, is CadenceThresholdAlert:
            return .green
        case is SpeedRangeAlert, is SpeedThresholdAlert:
            return .blue
        default:
            return .gray
        }
    }

    /// Concise textual description summarising the alert target/range.
    var description: String {
        switch self {
        case let alert as HeartRateRangeAlert:
            let lower = alert.target.lowerBound.value
            let upper = alert.target.upperBound.value
            return "Heart Rate: \(Int(lower))-\(Int(upper)) BPM"
        case let alert as HeartRateZoneAlert:
            return "Heart Rate Zone: \(alert.zone)"
        case let alert as PowerRangeAlert:
            let lower = alert.target.lowerBound.value
            let upper = alert.target.upperBound.value
            return "Power: \(Int(lower))-\(Int(upper)) W"
        case let alert as PowerThresholdAlert:
            return "Power: \(Int(alert.target.value)) W"
        case let alert as PowerZoneAlert:
            return "Power Zone: \(alert.zone)"
        case let alert as CadenceRangeAlert:
            let lower = alert.target.lowerBound.value
            let upper = alert.target.upperBound.value
            return "Cadence: \(Int(lower))-\(Int(upper)) RPM"
        case let alert as CadenceThresholdAlert:
            return "Cadence: \(Int(alert.target.value)) RPM"
        case let alert as SpeedRangeAlert:
            let lower = alert.target.lowerBound.value
            let upper = alert.target.upperBound.value
            return "Speed: \(String(format: "%.1f", lower))-\(String(format: "%.1f", upper)) \(alert.target.lowerBound.unit.symbol)"
        case let alert as SpeedThresholdAlert:
            return "Speed: \(String(format: "%.1f", alert.target.value)) \(alert.target.unit.symbol)"
        default:
            return "Target Zone Alert"
        }
    }
}

public extension Array where Element == Double {
    /// Calculates the arithmetic mean of a heart-rate sample collection.
    /// Returns `nil` when the collection is empty.
    func averageHeartRate() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}
