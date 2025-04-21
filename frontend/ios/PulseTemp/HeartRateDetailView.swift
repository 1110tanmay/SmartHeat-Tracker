import SwiftUI
import Charts

struct HeartRateDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // Heart Rate Range
                VStack {
                    Text("RANGE")
                        .font(.caption)
                        .foregroundColor(.gray)

                    if let min = healthKitManager.heartRateData.map(\.bpm).min(),
                       let max = healthKitManager.heartRateData.map(\.bpm).max() {
                        Text("\(min) - \(max) BPM")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    } else {
                        Text("-")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }

                // Heart Rate Chart (simplified for compiler)
                if !healthKitManager.heartRateData.isEmpty {
                    Chart {
                        ForEach(healthKitManager.heartRateData) { point in
                            let isLatest = point.id == healthKitManager.heartRateData.last?.id
                            let color: Color = isLatest ? .red : .blue

                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("BPM", point.bpm)
                            )
                            .foregroundStyle(color)
                        }
                    }
                    .frame(height: 200)
                    .padding()
                } else {
                    Text("No heart rate data available.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Latest Reading (from live sample)
                if let bpm = healthKitManager.latestHeartRate {
                    VStack {
                        Text("Latest: \(currentTime())")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text("\(Int(bpm)) BPM")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(12)
                }

                // Navigation to Trends page (no argument)
                NavigationLink(destination: TrendsView()) {
                    Text("Show More Heart Rate Data")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Heart Rate Details")
        .onAppear {
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Format Current Time
    func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    // MARK: - Timer Logic
    func startPolling() {
        healthKitManager.fetchHeartRateTrend()
        healthKitManager.fetchLatestHeartRate()

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            healthKitManager.fetchHeartRateTrend()
            healthKitManager.fetchLatestHeartRate()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }
}

