import Foundation
import WorkoutKit
import HealthKit
import SwiftUI

public extension Array where Element == Double {
    /// Calculates the arithmetic mean of a heart-rate sample collection.
    /// Returns `nil` when the collection is empty.
    func averageHeartRate() -> Double? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Double(count)
    }
}