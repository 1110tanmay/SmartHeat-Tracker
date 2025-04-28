import SwiftUI
import Charts

struct DistanceDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"
    @State private var timer: Timer?
    
    @State private var isLoading = true
    @State private var navigateToTrends = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Hidden NavigationLink (manual trigger)
                NavigationLink(destination: TrendsView(), isActive: $navigateToTrends) {
                    EmptyView()
                }
                .hidden()

                if isLoading {
                    ProgressView("Loading distance data...")
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding()
                } else {
                    let distanceData = healthKitManager.distanceTrendData.map { point in
                        (
                            timestamp: point.timestamp,
                            distance: distanceUnit == "miles"
                                ? kmToMiles(point.distance)
                                : point.distance
                        )
                    }

                    let totalDistance = distanceData.reduce(0) { $0 + $1.distance }
                    let totalDistanceText = String(format: "%.2f %@", totalDistance, distanceUnit)

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

                    // Total Distance (Last 6 Hours)
                    VStack {
                        Text("Total (Last 6 Hours)")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text(totalDistanceText)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(12)

                    // Navigation Button
                    Button(action: {
                        stopPolling()
                        navigateToTrends = true
                    }) {
                        Text("Show More Distance Data")
                            .foregroundColor(.blue)
                            .fontWeight(.semibold)
                    }
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Distance Covered")
        .onAppear {
            isLoading = true
            healthKitManager.fetchDistanceTrend()
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Timer Polling
    func startPolling() {
        healthKitManager.fetchDistanceTrend()

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            healthKitManager.fetchDistanceTrend()
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Helpers
    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    func kmToMiles(_ km: Double) -> Double {
        km * 0.621371
    }
}

