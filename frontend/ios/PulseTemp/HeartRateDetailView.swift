import SwiftUI
import Charts

struct HeartRateDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var refreshTimer: Timer?

    var heartRateRange: String {
        guard let min = healthKitManager.heartRateData.map({ $0.bpm }).min(),
              let max = healthKitManager.heartRateData.map({ $0.bpm }).max() else {
            return "-"
        }
        return "\(String(format: "%.0f", min)) - \(String(format: "%.0f", max)) BPM"
    }

    var latestHeartRate: String {
        guard let latest = healthKitManager.latestHeartRate else { return "-" }
        return "\(String(format: "%.0f", latest)) BPM"
    }

    var latestTimestamp: String {
        guard let lastPoint = healthKitManager.heartRateData.last else { return "-" }
        return timeFormatter.string(from: lastPoint.timestamp)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // RANGE Display
                VStack {
                    Text("RANGE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(heartRateRange)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // Chart Title
                VStack(alignment: .leading, spacing: 10) {
                    Text("Heart Rate Trend")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading)

                    // Heart Rate Chart
                    Chart {
                        ForEach(healthKitManager.heartRateData) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("BPM", point.bpm)
                            )
                            .foregroundStyle(point.bpm == healthKitManager.heartRateData.last?.bpm ? Color.red : Color.blue)

                            PointMark(
                                x: .value("Time", point.timestamp),
                                y: .value("BPM", point.bpm)
                            )
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let bpmValue = value.as(Double.self) {
                                    Text(String(format: "%.0f", bpmValue))
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }

                // Latest Heart Rate Tile
                VStack {
                    Text("Latest: \(latestTimestamp)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text(latestHeartRate)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.red)
                .cornerRadius(12)
              
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Heart Rate Details")
        .onAppear {
          healthKitManager.fetchLatestHeartRateAndUpdateCoreTemp() // 🔥 Immediate fetch
            startTimer()                            // ⏱️ Start 10s auto-refresh
        }
        .onDisappear {
            stopTimer()                             // 🛑 Stop timer on exit
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private func startTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
          healthKitManager.fetchLatestHeartRateAndUpdateCoreTemp()
        }
    }

    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}
