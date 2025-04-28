import SwiftUI
import Charts

struct CaloriesDetailView: View {
    @EnvironmentObject var healthManager: HealthKitManager
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Calories Burned Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Chart or Placeholder
                if !healthManager.caloriesTrendData.isEmpty {
                    caloriesChart
                        .animation(.easeInOut(duration: 0.5), value: healthManager.caloriesTrendData)
                } else {
                    Text("No calorie data available.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Latest Highlight
                if let calories = healthManager.latestCalories {
                    VStack {
                        Text("Latest: \(currentTime())")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text("\(Int(calories)) kcal")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Calories Burned")
        .onAppear {
            healthManager.fetchCaloriesTrend()
            healthManager.fetchLatestCalories()
            startPolling()
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

