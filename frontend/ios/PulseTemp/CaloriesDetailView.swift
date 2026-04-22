import SwiftUI
import Charts

struct CaloriesDetailView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var timer: Timer?

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [Color.purple.opacity(0.15), Color.orange.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // HERO Metric Card
                    VStack(spacing: 12) {
                        Text("Active Energy Burned")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text("\(Int(healthManager.latestCalories ?? 0))")
                            .font(.system(size: 64, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    .scaleEffect(showContent ? 1 : 0.9)
                    .opacity(showContent ? 1 : 0)

                    // 📊 Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("ENERGY TREND", systemImage: "bolt.heart.fill")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.purple)
                            Spacer()
                            if let min = healthManager.caloriesTrendData.map(\.calories).min(),
                               let max = healthManager.caloriesTrendData.map(\.calories).max() {
                                Text("\(Int(min)) - \(Int(max)) kcal")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        
                        Chart {
                            ForEach(healthManager.caloriesTrendData) { point in
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Calories", point.calories)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.purple.opacity(0.3), .purple.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Calories", point.calories)
                                )
                                .foregroundStyle(.purple)
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
                        Label("METABOLIC INSIGHT", systemImage: "sparkles")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.purple)
                        
                        Text("Active energy burn is calculated from your movement and heart rate. It contributes significantly to your overall thermal output and core temperature regulation.")
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
        .navigationTitle("Calories")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthManager.fetchCaloriesTrend()
            healthManager.fetchLatestCalories()
            startPolling()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Chart
    private var caloriesChart: some View {
        Chart {
            ForEach(healthManager.caloriesTrendData) { point in
                let isLatest = point.id == healthManager.caloriesTrendData.last?.id
                let color: Color = isLatest ? .purple : .orange

                LineMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Calories", point.calories)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(color)

                PointMark(
                    x: .value("Time", point.timestamp),
                    y: .value("Calories", point.calories)
                )
                .foregroundStyle(color)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) {
                AxisGridLine()
                AxisValueLabel(format: .dateTime.hour().minute(), centered: true)
            }
        }
        .chartYAxis {
            AxisMarks()
        }
        .frame(height: 200)
        .padding()
    }

    // MARK: - Time Formatter
    func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    // MARK: - Timer Logic
    func startPolling() {
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            healthManager.fetchCaloriesTrend()
            healthManager.fetchLatestCalories()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}

