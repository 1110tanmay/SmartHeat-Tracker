import SwiftUI
import Charts

struct CoreTempDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"

    // MARK: - Computed Properties

    var convertedTempData: [CoreTempPoint] {
        healthKitManager.coreTempTrendData.map { point in
            let converted = temperatureUnit == "°F" ? celsiusToFahrenheit(point.temperature) : point.temperature
            return CoreTempPoint(timestamp: point.timestamp, temperature: converted)
        }
    }

    var tempRange: String {
        guard let min = convertedTempData.map({ $0.temperature }).min(),
              let max = convertedTempData.map({ $0.temperature }).max() else {
            return "-"
        }
        return String(format: "%.1f - %.1f%@", min, max, temperatureUnit)
    }

    var latestTemp: String {
        guard let latest = healthKitManager.latestCoreTemp else { return "-" }
        let temp = temperatureUnit == "°F" ? celsiusToFahrenheit(latest) : latest
        return String(format: "%.1f%@", temp, temperatureUnit)
    }

    var latestTimestamp: String {
        guard let lastPoint = healthKitManager.coreTempTrendData.last else { return "-" }
        return timeFormatter.string(from: lastPoint.timestamp)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Range display
                VStack {
                    Text("RANGE")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(tempRange)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }

                // Temperature graph
                Chart {
                    ForEach(convertedTempData) { point in
                        LineMark(
                            x: .value("Time", point.timestamp),
                            y: .value("Temperature", point.temperature)
                        )
                        .foregroundStyle(point.temperature == convertedTempData.last?.temperature ? Color.orange : Color.blue)
                    }
                }
                .frame(height: 200)
                .padding()

                // Latest temperature
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

                // Show more button
                Button(action: {
                    print("Show More Temperature Data tapped")
                }) {
                    Text("Show More Temperature Data")
                        .foregroundColor(.blue)
                        .fontWeight(.semibold)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Core Temperature")
    }

    // MARK: - Helpers
    func celsiusToFahrenheit(_ celsius: Double) -> Double {
        (celsius * 9/5) + 32
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }
}

