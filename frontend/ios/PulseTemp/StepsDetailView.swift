import SwiftUI
import Charts

struct StepsDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var timer: Timer?

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.teal.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // HERO Metric Card
                    VStack(spacing: 12) {
                        Text("Daily Steps Progress")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text("\(healthKitManager.latestSteps?.formatted() ?? "0")")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    .scaleEffect(showContent ? 1 : 0.9)
                    .opacity(showContent ? 1 : 0)

                    // 📊 Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("STEP TRENDS", systemImage: "figure.walk.motion")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.blue)
                            Spacer()
                            if let min = healthKitManager.stepsTrendData.map(\.steps).min(),
                               let max = healthKitManager.stepsTrendData.map(\.steps).max() {
                                Text("\(min.formatted()) - \(max.formatted())")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Chart {
                            ForEach(healthKitManager.stepsTrendData) { point in
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Steps", point.steps)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.blue.opacity(0.3), .blue.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Steps", point.steps)
                                )
                                .foregroundStyle(.blue)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .hour, count: 4)) { value in
                                AxisValueLabel(format: .dateTime.hour())
                                    .font(.system(size: 10, design: .rounded))
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel()
                                    .font(.system(size: 10, design: .rounded))
                            }
                        }
                        .frame(height: 220)
                    }
                    .padding(24)
                    .background(.thinMaterial)
                    .cornerRadius(32)
                    .padding(.horizontal)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                    // 💡 Insights Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("ACTIVITY INSIGHT", systemImage: "flame.fill")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.blue)
                        
                        Text("Walking is essential for regulating metabolism and cardiovascular health. Higher step counts correlate with better thermal regulation in humans.")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundColor(.secondary)
                            .lineSpacing(4)
                    }
                    .padding(24)
                    .background(Color.white.opacity(0.5))
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                    Spacer()
                }
            }
        }
        .navigationTitle("Steps")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthKitManager.fetchStepsTrend()
            startPolling()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Helpers
    func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    func startPolling() {
        fetchLiveSteps()

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchLiveSteps()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    func fetchLiveSteps() {
        healthKitManager.fetchLatestSteps()

        if let steps = healthKitManager.latestSteps {
            let now = Date()
            let point = StepPoint(timestamp: now, steps: steps)

            if healthKitManager.stepsTrendData.last?.timestamp != point.timestamp {
                healthKitManager.stepsTrendData.append(point)
            }
        }
    }
}

