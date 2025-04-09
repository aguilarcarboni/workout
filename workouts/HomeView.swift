import SwiftUI
import Charts

struct HomeView: View {
    // Sample data for charts
    let weeklyVolume = [
        (day: "Mon", volume: 2500),
        (day: "Tue", volume: 3200),
        (day: "Wed", volume: 2800),
        (day: "Thu", volume: 3600),
        (day: "Fri", volume: 3100),
        (day: "Sat", volume: 4200),
        (day: "Sun", volume: 2900)
    ]
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemBackground),
                        Color(.systemBackground).opacity(0.8)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Summary Cards Grid
                        VStack(spacing: 15) {
                            Text("Overview")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 15) {
                                StatCard(title: "Total Volume", value: "22,300", unit: "kg")
                                StatCard(title: "Workouts", value: "16", unit: "this month")
                            }
                            
                            HStack(spacing: 15) {
                                StatCard(title: "Streak", value: "5", unit: "days")
                                StatCard(title: "PR's", value: "8", unit: "this month")
                            }
                        }
                        .padding(.horizontal)
                        
                        // Weekly Volume Chart
                        VStack(spacing: 20) {
                            Text("Weekly Progress")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Chart {
                                ForEach(weeklyVolume, id: \.day) { item in
                                    BarMark(
                                        x: .value("Day", item.day),
                                        y: .value("Volume", item.volume)
                                    )
                                    .foregroundStyle(Color("AccentColor"))
                                }
                            }
                            .frame(height: 200)
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 15))
                        }
                        .padding(.horizontal)
                        
                        // Recent Workouts
                        VStack(spacing: 20) {
                            Text("Recent Workouts")
                                .font(.title2)
                                .fontWeight(.bold)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            ForEach(1...3, id: \.self) { _ in
                                WorkoutRow()
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Dashboard")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundStyle(Color("AccentColor"))
                
                Text(unit)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}

struct WorkoutRow: View {
    var body: some View {
        HStack(spacing: 15) {
            Circle()
                .fill(Color("AccentColor"))
                .frame(width: 40, height: 40)
                .overlay(
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.system(.body, design: .rounded))
                        .foregroundStyle(.black)
                )
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Upper Body")
                    .font(.system(.headline, design: .rounded))
                
                Text("45 minutes • 8 exercises")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
            Text("2h ago")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 15))
    }
}