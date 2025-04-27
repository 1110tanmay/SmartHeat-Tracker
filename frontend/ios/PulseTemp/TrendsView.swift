import SwiftUI
import Charts

struct TrendsView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

    @State private var selectedTimeframe: Timeframe = .day

    enum Timeframe: String, CaseIterable, Identifiable {
        case day = "Day"
        case week = "Week"
        case month = "Month"
        case year = "Year"

        var id: String { self.rawValue }

        var calendarComponent: Calendar.Component {
            switch self {
            case .day: return .day
            case .week: return .weekOfYear
            case .month: return .month
            case .year: return .year
            }
        }
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Timeframe Picker
                    Picker("Timeframe", selection: $selectedTimeframe) {
                        ForEach(Timeframe.allCases) { timeframe in
                            Text(timeframe.rawValue).tag(timeframe)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    .padding()

                    Group {
                        // Core Temperature
                        if !filteredCoreTemp.isEmpty {
                            TrendChart(title: "Core Temperature Trends (°C)", color: .orange, data: filteredCoreTemp.map { ($0.timestamp, $0.temp) })
                        } else {
                            NoDataView(title: "Core Temperature")
                        }

                        // Heart Rate
                        if !filteredHeartRate.isEmpty {
                            TrendChart(title: "Heart Rate Trends (\(selectedTimeframe.rawValue))", color: .red, data: filteredHeartRate.map { ($0.timestamp, Double($0.bpm)) })
                        } else {
                            NoDataView(title: "Heart Rate")
                        }

                        // Steps
                        if !filteredSteps.isEmpty {
                            TrendChart(title: "Steps Trends (\(selectedTimeframe.rawValue))", color: .blue, data: filteredSteps.map { ($0.timestamp, Double($0.steps)) })
                        } else {
                            NoDataView(title: "Steps")
                        }

                        // Calories
                        if !filteredCalories.isEmpty {
                            TrendChart(title: "Calories Burned Trends (\(selectedTimeframe.rawValue))", color: .purple, data: filteredCalories.map { ($0.timestamp, $0.calories) })
                        } else {
                            NoDataView(title: "Calories")
                        }

                        // Distance
                        if !filteredDistance.isEmpty {
                            TrendChart(title: "Distance Covered Trends (\(distanceUnit))", color: .green, data: filteredDistance.map { ($0.timestamp, $0.distance) })
                        } else {
                            NoDataView(title: "Distance")
                        }
                    }

                    Spacer()
                }
                .padding()
            }
            .navigationTitle("Trends")
            .onAppear {
                healthKitManager.fetchHistoricalHeartRate()
                healthKitManager.fetchHistoricalSteps()
                healthKitManager.fetchHistoricalCalories()
                healthKitManager.fetchHistoricalDistance()
                healthKitManager.fetchHistoricalCoreTemp()
            }
            .onChange(of: selectedTimeframe) { _ in
                // No need to fetch again on change, just filter the already available data
                filterAllData()
            }
        }
    }

    // MARK: - Filtering Logic
    private func isWithinSelectedTimeframe(_ date: Date) -> Bool {
        let calendar = Calendar.current
        switch selectedTimeframe {
        case .day:
            return calendar.isDateInToday(date)
        case .week:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)
        case .month:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .month)
        case .year:
            return calendar.isDate(date, equalTo: Date(), toGranularity: .year)
        }
    }

    private var filteredCoreTemp: [CoreTempPoint] {
        healthKitManager.historicalCoreTemp.filter { isWithinSelectedTimeframe($0.timestamp) }
    }

    private var filteredHeartRate: [HeartRatePoint] {
        healthKitManager.historicalHeartRate.filter { isWithinSelectedTimeframe($0.timestamp) }
    }

    private var filteredSteps: [StepPoint] {
        healthKitManager.historicalSteps.filter { isWithinSelectedTimeframe($0.timestamp) }
    }

    private var filteredCalories: [CaloriePoint] {
        healthKitManager.historicalCalories.filter { isWithinSelectedTimeframe($0.timestamp) }
    }

    private var filteredDistance: [DistancePoint] {
        healthKitManager.historicalDistance.filter { isWithinSelectedTimeframe($0.timestamp) }
    }

    private func filterAllData() {
        // Just trigger recomputation when timeframe changes
        _ = filteredCoreTemp
        _ = filteredHeartRate
        _ = filteredSteps
        _ = filteredCalories
        _ = filteredDistance
    }
}

// MARK: - TrendChart Component
struct TrendChart: View {
    let title: String
    let color: Color
    let data: [(Date, Double)]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .padding(.leading)

            Chart {
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    LineMark(
                        x: .value("Time", point.0),
                        y: .value("Value", point.1)
                    )
                    .foregroundStyle(color)
                }
            }
            .frame(height: 200)
            .padding(.horizontal)
        }
    }
}

// MARK: - NoData View
struct NoDataView: View {
    let title: String

    var body: some View {
        VStack {
            Text("No \(title) data available.")
                .foregroundColor(.gray)
                .padding()
        }
    }
}

