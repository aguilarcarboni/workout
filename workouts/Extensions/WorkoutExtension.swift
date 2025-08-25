import Foundation
import WorkoutKit
import HealthKit
import SwiftUI

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
