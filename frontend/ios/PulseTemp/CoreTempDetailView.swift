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

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [Color.orange.opacity(0.15), Color.red.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // HERO Metric Card
                    VStack(spacing: 12) {
                        Text("Estimated Core Temperature")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text(latestTemp)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    .scaleEffect(showContent ? 1 : 0.9)
                    .opacity(showContent ? 1 : 0)

                    // 📊 Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("24H TREND", systemImage: "waveform.path.ecg")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.orange)
                            Spacer()
                            Text(tempRange)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        Chart {
                            ForEach(convertedTempData) { point in
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Temperature", point.temp)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.orange.opacity(0.3), .orange.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("Temperature", point.temp)
                                )
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                .interpolationMethod(.catmullRom)
                            }
                        }
                        .chartYScale(domain: customYDomain)
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
                        Label("THERMAL INSIGHT", systemImage: "lightbulb.fill")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.orange)
                        
                        Text("Core body temperature is estimated based on your heart rate and activity levels. This is a reference value for monitoring thermal strain during workouts.")
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
        .navigationTitle("Core Temperature")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            refreshData()
            startTimer()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
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

