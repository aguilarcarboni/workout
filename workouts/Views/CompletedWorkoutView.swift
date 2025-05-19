import SwiftUI
import HealthKit
import Charts

struct CompletedWorkoutView: View {
    let workout: HKWorkout
    @Environment(\.dismiss) private var dismiss
    @StateObject private var healthManager = HealthManager.shared
    @State private var heartRateData: [Double] = []
    @State private var isLoadingHeartRate = true
    @State private var splits: [WorkoutSplit] = []
    @State private var selectedTab = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header
                HStack {
                    VStack(alignment: .leading) {
                        Text(workout.workoutActivityType.name)
                            .font(.title)
                            .bold()
                        Text(workout.startDate.formatted(date: .long, time: .shortened))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
                .padding(.horizontal)
                
                // Main Stats Grid
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {
                    StatView(title: "Time", value: formatDuration(workout.duration))
                    
                    if let distance = workout.totalDistance?.doubleValue(for: .mile()) {
                        StatView(title: "Distance", value: String(format: "%.2f mi", distance))
                        // Show pace for distance-based workouts
                        let paceMinutes = workout.duration / 60.0 / distance
                        StatView(title: "Avg Pace", value: String(format: "%d'%02d\"/mi", Int(paceMinutes), Int((paceMinutes.truncatingRemainder(dividingBy: 1) * 60))))
                    }
                    
                    if let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                        StatView(title: "Calories", value: "\(Int(calories))")
                    }
                    
                    if !heartRateData.isEmpty {
                        if let avg = heartRateData.average {
                            StatView(title: "Avg HR", value: "\(Int(avg)) BPM")
                        }
                        if let max = heartRateData.max() {
                            StatView(title: "Max HR", value: "\(Int(max)) BPM")
                        }
                    }
                }
                .padding()
                
                // Segmented Control for Details/Splits
                Picker("View", selection: $selectedTab) {
                    Text("Details").tag(0)
                    Text("Splits").tag(1)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                if selectedTab == 0 {
                    // Heart Rate Chart
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Heart Rate")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if isLoadingHeartRate {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if !heartRateData.isEmpty {
                            Chart {
                                ForEach(Array(heartRateData.enumerated()), id: \.offset) { index, hr in
                                    LineMark(
                                        x: .value("Time", index),
                                        y: .value("BPM", hr)
                                    )
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            
                            // Heart Rate Zones
                            let zones = calculateHeartRateZones(heartRateData)
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Time in Heart Rate Zones")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                ForEach(zones.sorted(by: { $0.key > $1.key }), id: \.key) { zone, percentage in
                                    HRZoneRow(zone: zone, percentage: percentage)
                                }
                            }
                            .padding(.horizontal)
                        } else {
                            Text("No heart rate data available")
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                        }
                    }
                    
                    // Effort Score
                    if !heartRateData.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Effort")
                                .font(.headline)
                                .padding(.horizontal)
                            
                            let effortScore = calculateEffortScore(heartRateData)
                            HStack {
                                Text("\(effortScore)")
                                    .font(.system(size: 36, weight: .bold))
                                Text("/ 100")
                                    .font(.title2)
                                    .foregroundColor(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .center)
                            
                            Text("Based on your heart rate zones and workout duration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .padding()
                    }
                    
                } else {
                    // Splits View
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Splits")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        if let distance = workout.totalDistance?.doubleValue(for: .mile()) {
                            ForEach(generateSplits(distance: distance, duration: workout.duration), id: \.mile) { split in
                                SplitRow(split: split)
                            }
                        } else {
                            Text("No split data available")
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                }
            }
            .padding(.vertical)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
            }
        }
        .onAppear {
            loadHeartRateData()
        }
    }
    
    private func loadHeartRateData() {
        Task {
            do {
                let data = try await healthManager.fetchHeartRateData(for: workout)
                await MainActor.run {
                    self.heartRateData = data
                    self.isLoadingHeartRate = false
                }
            } catch {
                print("Error fetching heart rate data: \(error)")
                await MainActor.run {
                    self.isLoadingHeartRate = false
                }
            }
        }
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute, .second]
        formatter.zeroFormattingBehavior = .pad
        formatter.unitsStyle = .positional
        return formatter.string(from: duration) ?? "N/A"
    }
    
    private func calculateHeartRateZones(_ heartRates: [Double]) -> [Int: Double] {
        let maxHR = 220.0 // This should ideally be personalized
        var zones: [Int: Int] = [:]
        
        for hr in heartRates {
            let percentage = hr / maxHR * 100
            let zone = Int(ceil(percentage / 10))
            zones[zone, default: 0] += 1
        }
        
        let total = Double(heartRates.count)
        return zones.mapValues { Double($0) / total * 100 }
    }
    
    private func calculateEffortScore(_ heartRates: [Double]) -> Int {
        let maxHR = 220.0 // This should ideally be personalized
        let avgHR = heartRates.average ?? 0
        let percentage = avgHR / maxHR
        let durationFactor = min(workout.duration / 3600, 2) // Cap at 2 hours
        let effortScore = Int((percentage * 100) * (0.7 + (durationFactor * 0.15)))
        return min(max(effortScore, 0), 100)
    }
    
    private func generateSplits(distance: Double, duration: TimeInterval) -> [WorkoutSplit] {
        var splits: [WorkoutSplit] = []
        let totalMiles = Int(ceil(distance))
        let pacePerMile = duration / distance
        
        for mile in 1...totalMiles {
            let isLastSplit = mile == totalMiles
            let splitDistance = isLastSplit ? distance.truncatingRemainder(dividingBy: 1.0) : 1.0
            let splitDuration = pacePerMile * splitDistance
            
            splits.append(WorkoutSplit(
                mile: mile,
                distance: splitDistance,
                duration: splitDuration,
                pace: splitDuration / splitDistance
            ))
        }
        
        return splits
    }
}

struct StatView: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity)
    }
}

struct HRZoneRow: View {
    let zone: Int
    let percentage: Double
    
    var body: some View {
        HStack {
            Text("Zone \(zone)")
                .font(.caption)
            Spacer()
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.gray.opacity(0.2))
                    Rectangle()
                        .fill(zoneColor)
                        .frame(width: geometry.size.width * CGFloat(percentage / 100))
                }
            }
            .frame(height: 8)
            .cornerRadius(4)
            Text(String(format: "%.0f%%", percentage))
                .font(.caption)
                .frame(width: 40, alignment: .trailing)
        }
    }
    
    private var zoneColor: Color {
        switch zone {
        case 9...10: return .red
        case 7...8: return .orange
        case 5...6: return .yellow
        case 3...4: return .green
        default: return .blue
        }
    }
}

struct SplitRow: View {
    let split: WorkoutSplit
    
    var body: some View {
        HStack {
            Text("Mile \(split.mile)")
                .font(.subheadline)
            Spacer()
            Text(String(format: "%.2f mi", split.distance))
                .font(.subheadline)
            Spacer()
            Text(formatPace(split.pace))
                .font(.subheadline)
        }
        .padding(.vertical, 4)
    }
    
    private func formatPace(_ pace: TimeInterval) -> String {
        let minutes = Int(pace / 60)
        let seconds = Int(pace.truncatingRemainder(dividingBy: 60))
        return String(format: "%d'%02d\"", minutes, seconds)
    }
}

struct WorkoutSplit {
    let mile: Int
    let distance: Double
    let duration: TimeInterval
    let pace: TimeInterval
}

extension Collection where Element: BinaryFloatingPoint {
    var average: Element? {
        guard !isEmpty else { return nil }
        return reduce(0, +) / Element(count)
    }
} 