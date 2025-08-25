import Foundation

/// Shared formatting utilities to avoid code duplication across the project.
/// - Note: All distances are assumed to be provided in **metres** and paces in **seconds per kilometre**.
public func formatDuration(_ duration: TimeInterval) -> String {
    let hours = Int(duration) / 3600
    let minutes = Int(duration) % 3600 / 60
    let seconds = Int(duration) % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, seconds)
    } else {
        return String(format: "%d:%02d", minutes, seconds)
    }
}

/// Formats a distance (in metres) into a human-readable string.
/// Distances >= 1000 m are shown in kilometres with two decimal places, otherwise in metres.
public func formatDistance(_ distance: Double) -> String {
    if distance >= 1000 {
        return String(format: "%.2f km", distance / 1000)
    } else {
        return String(format: "%.0f m", distance)
    }
}

/// Formats a running pace (seconds per kilometre) into a string like `4'30"/km`.
public func formatPace(_ pace: Double) -> String {
    let minutes = Int(pace) / 60
    let seconds = Int(pace) % 60
    return String(format: "%d'%02d\"/km", minutes, seconds)
}

/// Formats a date into a human-readable string.
public func formatDate(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    return formatter.string(from: date)
}

/// Formats a time into a human-readable string.
public func formatTime(_ date: Date) -> String {
    let formatter = DateFormatter()
    formatter.timeStyle = .short
    return formatter.string(from: date)
}

/// Returns the average of a collection of heart-rate samples (in BPM).
/// - Parameter heartRates: Collection of Double values representing heart-rate samples.
/// - Returns: Arithmetic mean or `nil` if the collection is empty.
public func averageHeartRate(_ heartRates: [Double]) -> Double? {
    heartRates.averageHeartRate()
}