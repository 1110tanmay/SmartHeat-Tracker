import SwiftUI
import Charts

struct CoreTempDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @State private var refreshTimer: Timer?

    // MARK: - Computed Properties

    var convertedTempData: [CoreTempPoint] {
        healthKitManager.coreTempTrendData.map { point in
            let converted = temperatureUnit == "°F"
                ? celsiusToFahrenheit(point.temp)
                : point.temp

            return CoreTempPoint(
                timestamp: point.timestamp,
                temp: converted
            )
        }
    }

    var tempRange: String {
        guard let min = convertedTempData.map({ $0.temp }).min(),
              let max = convertedTempData.map({ $0.temp }).max() else {
            return "-"
        }
        return String(format: "%.4f - %.4f%@", min, max, temperatureUnit)
    }

    var latestTemp: String {
        let latestSource = healthKitManager.latestCoreTemp ?? healthKitManager.coreTempTrendData.last?.temp
        guard let latest = latestSource else { return "-" }
        let temp = temperatureUnit == "°F" ? celsiusToFahrenheit(latest) : latest
        return String(format: "%.4f%@", temp, temperatureUnit)
    }

    var latestTimestamp: String {
        if let lastPoint = healthKitManager.coreTempTrendData.last {
            return timeFormatter.string(from: lastPoint.timestamp)
        }
        return healthKitManager.latestCoreTemp != nil ? timeFormatter.string(from: Date()) : "-"
    }

    var customYDomain: ClosedRange<Double> {
        let temps = convertedTempData.map { $0.temp }
        guard let min = temps.min(), let max = temps.max() else {
            return 36.0...38.0 // fallback
        }
        let lower = min - 0.2
        let upper = max + 0.2
        return lower...upper
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // RANGE Display
                VStack {
                    Text("RANGE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(tempRange)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // Chart Title
                VStack(alignment: .leading, spacing: 10) {
                    Text("Estimated from HR")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.leading)

                    // Temperature Chart
                    Chart {
                        ForEach(convertedTempData) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Temperature", point.temp)
                            )
                            .foregroundStyle(point.temp == convertedTempData.last?.temp ? Color.orange : Color.blue)

                            PointMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Temperature", point.temp)
                            )
                        }
                    }
                    .chartYScale(domain: customYDomain)
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let doubleVal = value.as(Double.self) {
                                    Text(String(format: "%.4f", doubleVal))
                                }
                            }
                        }
                    }
                    .frame(height: 200)
                    .padding(.horizontal)
                }

                // Latest CT Tile
                VStack {
                    Text("Latest: \(latestTimestamp)")
                        .foregroundColor(.white)
                        .fontWeight(.bold)
                    Text(latestTemp)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .cornerRadius(12)
               
                Spacer()
            }
            .padding()
        }
        .navigationTitle("Core Temperature")
        .onAppear {
            refreshData()
            startTimer()
        }
        .onDisappear {
            stopTimer()
        }

    }

    func celsiusToFahrenheit(_ celsius: Double) -> Double {
        (celsius * 9/5) + 32
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private func refreshData() {
        // Keep latest CT and trendline in sync while detail screen is visible.
        healthKitManager.fetchLatestHeartRateAndUpdateCoreTemp()
        healthKitManager.fetchCoreTempTrend()
    }

    private func startTimer() {
        refreshTimer = Timer.scheduledTimer(withTimeInterval: 10, repeats: true) { _ in
            refreshData()
        }
    }

    private func stopTimer() {
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
}

