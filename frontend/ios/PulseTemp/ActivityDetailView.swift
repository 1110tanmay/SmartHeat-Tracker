import SwiftUI
import Charts

struct ActivityDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"
    @State private var timer: Timer?

    var convertedDistanceTrend: [DistancePoint] {
        healthKitManager.distanceTrendData.map { point in
            var updated = point
            updated.distance = distanceUnit == "miles" ? kmToMiles(point.distance) : point.distance
            return updated
        }
    }

    var totalDistanceText: String {
        guard let latest = convertedDistanceTrend.last else { return "-" }
        return String(format: "%.2f %@", latest.distance, distanceUnit)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // 🢍 Steps Walked
                VStack {
                    Text("Steps Walked")
                        .font(.headline)
                    Text("\(healthKitManager.latestSteps ?? 0) steps")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Chart {
                    ForEach(healthKitManager.stepsTrendData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Steps", point.steps)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.blue)
                    }
                }
                .frame(height: 200)
                .padding()

                // 🔥 Calories Burned
                VStack {
                    Text("Calories Burned")
                        .font(.headline)
                    Text("\(Int(healthKitManager.latestCalories ?? 0)) kcal")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Chart {
                    ForEach(healthKitManager.caloriesTrendData) { point in
                        LineMark(
                          x: .value("Time", point.date),
                            y: .value("Calories", point.calories)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.red)
                    }
                }
                .frame(height: 200)
                .padding()

                // 🏃‍♂️ Distance Traveled
                VStack {
                    Text("Distance Traveled")
                        .font(.headline)
                    Text(totalDistanceText)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                Chart {
                    ForEach(convertedDistanceTrend) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Distance (\(distanceUnit))", point.distance)
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.green)
                    }
                }
                .frame(height: 200)
                .padding()

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Activity Details")
        .onAppear {
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Conversion
    func kmToMiles(_ km: Double) -> Double {
        km * 0.621371
    }

    // MARK: - Timer-based Polling
    func startPolling() {
        fetchLiveSteps()
        fetchLiveCalories()
        fetchLiveDistance()

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchLiveSteps()
            fetchLiveCalories()
            fetchLiveDistance()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Live Appending Functions
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

    func fetchLiveCalories() {
        healthKitManager.fetchLatestCalories()
        if let calories = healthKitManager.latestCalories {
          let now = Date()
          let point = CaloriePoint(date: now, calories: calories)
          if healthKitManager.caloriesTrendData.last?.date != point.date {
              healthKitManager.caloriesTrendData.append(point)
          }
            }
        }

    func fetchLiveDistance() {
        healthKitManager.fetchLatestDistance()
        if let distance = healthKitManager.latestDistance {
          let now = Date()
          let point = DistancePoint(timestamp: now, distance: distance)
            if healthKitManager.distanceTrendData.last?.timestamp != point.timestamp {
                healthKitManager.distanceTrendData.append(point)
            }
        }
    }
}
