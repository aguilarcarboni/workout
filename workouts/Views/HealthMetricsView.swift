import SwiftUI
import HealthKit
import FoundationModels

struct HealthMetricsView: View {
    
    @StateObject private var healthManager = HealthManager.shared
    @State private var metrics: [MetricDisplay] = []
    @State private var aiSummary: String = ""
    @State private var isGenerating = false
    @State private var isLoading = true
    
    private let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if isLoading {
                        ProgressView("Loading health metrics...")
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else {
                        LazyVGrid(columns: columns, spacing: 12) {
                            ForEach(metrics) { metric in
                                MetricCard(title: metric.title, value: metric.value)
                            }
                        }
                    }
                    
                    if !aiSummary.isEmpty {
                        Text(aiSummary)
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color(.systemGray6))
                            .cornerRadius(10)
                    }
                    
                    Button {
                        Task { await generateAISummary() }
                    } label: {
                        if isGenerating {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .frame(maxWidth: .infinity)
                        } else {
                            Text("Analyze with AI")
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating || metrics.isEmpty)
                    
                    Button("Refresh") {
                        Task { await loadMetrics() }
                    }
                    .buttonStyle(.bordered)
                }
                .padding()
            }
            .navigationTitle("Health Metrics")
            .task {
                await loadMetrics()
            }
        }
    }
    
    private func loadMetrics() async {
        let values = await healthManager.fetchDailyMetrics()
        let sorted = values.keys.sorted()
        let mapped = sorted.map { MetricDisplay(title: $0, value: values[$0] ?? "N/A") }
        await MainActor.run {
            self.metrics = mapped
            self.isLoading = false
        }
    }
    
    private func generateAISummary() async {
        guard !metrics.isEmpty else { return }
        
        guard #available(iOS 26.0, *) else {
            await MainActor.run {
                aiSummary = "AI analysis requires iOS 26 or later."
            }
            return
        }
        
        await performAIGeneration()
    }
    
    @available(iOS 26.0, *)
    private func performAIGeneration() async {
        await MainActor.run { isGenerating = true }
        
        let metricsText = metrics.map { "\($0.title): \($0.value)" }.joined(separator: "\n")
        
        let instructions = """
        You are a privacy-first, on-device wellness coach. Analyze the provided health metrics, identify trends, correlations (e.g., steps vs. sleep, HRV vs. recovery), and deliver concise, actionable advice. Keep tone supportive and direct. Highlight 3-5 key insights and 3 specific next steps.
        """
        
        let prompt = Prompt(metricsText)
        
        do {
            let session = LanguageModelSession(instructions: instructions)
            let response = try await session.respond(to: prompt)
            await MainActor.run {
                aiSummary = response.content
            }
        } catch {
            await MainActor.run {
                aiSummary = "Error generating AI summary: \(error.localizedDescription)"
            }
        }
        
        await MainActor.run { isGenerating = false }
    }
}

struct MetricDisplay: Identifiable {
    let id = UUID()
    let title: String
    let value: String
}

struct MetricCard: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemGray6))
        .cornerRadius(10)
    }
}

