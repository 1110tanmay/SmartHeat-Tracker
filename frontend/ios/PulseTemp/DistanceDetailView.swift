import SwiftUI
import Charts

struct DistanceDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Convert distance values
                let distanceData = healthKitManager.distanceTrendData.map { point in
                    (
                        timestamp: point.timestamp,
                        distance: distanceUnit == "miles"
                            ? kmToMiles(point.distance)
                            : point.distance
                    )
                }

                let latestDistanceText = distanceData.last.map {
                    String(format: "%.2f %@", $0.distance, distanceUnit)
                } ?? "-"

                // Title
                Text("Distance Covered Details")
                    .font(.largeTitle)
                    .fontWeight(.bold)

                // Chart
                if !distanceData.isEmpty {
                    Chart {
                        ForEach(distanceData, id: \.timestamp) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Distance (\(distanceUnit))", point.distance)
                            )
                            .foregroundStyle(Color.blue)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                } else {
                    Text("No distance data available.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Latest
                if let latest = distanceData.last {
                    VStack {
                        Text("Latest: \(formattedTime(latest.timestamp))")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text(latestDistanceText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)
                }

                // Navigation to Trends Page
                NavigationLink(destination: TrendsView()) {
                    Text("Show More Distance Data")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Distance Covered")
        .onAppear {
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Format Timestamp
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Conversion
    func kmToMiles(_ km: Double) -> Double {
        km * 0.621371
    }

    // MARK: - Timer Polling
    func startPolling() {
        fetchLiveDistance()

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchLiveDistance()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
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

