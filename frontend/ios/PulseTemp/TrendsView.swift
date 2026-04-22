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

    @State private var showContent = false

    var body: some View {
        NavigationView {
            ZStack {
                // Premium Background
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.teal.opacity(0.1), Color.white],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        
                        // Custom Timeframe Picker
                        HStack(spacing: 0) {
                            ForEach(Timeframe.allCases) { timeframe in
                                Button(action: {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                                        selectedTimeframe = timeframe
                                    }
                                }) {
                                    Text(timeframe.rawValue)
                                        .font(.system(.subheadline, design: .rounded))
                                        .fontWeight(selectedTimeframe == timeframe ? .bold : .medium)
                                        .foregroundColor(selectedTimeframe == timeframe ? .primary : .secondary)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(
                                            ZStack {
                                                if selectedTimeframe == timeframe {
                                                    RoundedRectangle(cornerRadius: 12)
                                                        .fill(Color.white)
                                                        .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                                                        .matchedGeometryEffect(id: "activeTab", in: tabAnimation)
                                                }
                                            }
                                        )
                                }
                            }
                        }
                        .padding(4)
                        .background(.thinMaterial)
                        .cornerRadius(16)
                        .padding(.horizontal)
                        .padding(.top, 10)
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 10)

                        VStack(spacing: 24) {
                            // Core Temperature
                            TrendCard(
                                title: "Core Temperature (\(temperatureUnit))",
                                icon: "thermometer",
                                color: .orange,
                                data: filteredCoreTemp.map { ($0.timestamp, convertTemp($0.temp)) },
                                yRange: temperatureUnit == "°F" ? 95.0...104.0 : 35.0...40.0
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring().delay(0.1), value: showContent)

                            // Heart Rate
                            TrendCard(
                                title: "Heart Rate (BPM)",
                                icon: "heart.fill",
                                color: .red,
                                data: filteredHeartRate.map { ($0.timestamp, Double($0.bpm)) }
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring().delay(0.2), value: showContent)

                            // Steps
                            TrendCard(
                                title: "Steps Count",
                                icon: "figure.walk",
                                color: .blue,
                                data: filteredSteps.map { ($0.timestamp, Double($0.steps)) }
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring().delay(0.3), value: showContent)

                            // Calories
                            TrendCard(
                                title: "Calories Burned",
                                icon: "bolt.fill",
                                color: .purple,
                                data: filteredCalories.map { ($0.timestamp, $0.calories) }
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring().delay(0.4), value: showContent)

                            // Distance
                            TrendCard(
                                title: "Distance (\(distanceUnit))",
                                icon: "map.fill",
                                color: .green,
                                data: filteredDistance.map { ($0.timestamp, $0.distance) }
                            )
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(.spring().delay(0.5), value: showContent)
                        }
                        .padding(.bottom, 30)
                    }
                }
                .navigationTitle("Historical Trends")
                .onAppear {
                    healthKitManager.fetchHeartRateTrend()
                    healthKitManager.fetchCoreTempTrend()
                    healthKitManager.fetchHistoricalHeartRate()
                    healthKitManager.fetchHistoricalSteps()
                    healthKitManager.fetchHistoricalCalories()
                    healthKitManager.fetchHistoricalDistance()
                    healthKitManager.fetchHistoricalCoreTemp()
                    
                    withAnimation(.easeOut(duration: 0.8)) {
                        showContent = true
                    }
                }
            }
        }
    }
    
    @Namespace private var tabAnimation

    // MARK: - Filtering Logic (unchanged)
    private var mergedCoreTempData: [CoreTempPoint] {
        let merged = healthKitManager.historicalCoreTemp + healthKitManager.coreTempTrendData
        let uniqueByTimestamp = Dictionary(merged.map { ($0.timestamp, $0) }, uniquingKeysWith: { current, _ in current })
        return uniqueByTimestamp.values.sorted { $0.timestamp < $1.timestamp }
    }

    private var mergedHeartRateData: [HeartRatePoint] {
        let merged = healthKitManager.historicalHeartRate + healthKitManager.heartRateData
        let uniqueByTimestamp = Dictionary(merged.map { ($0.timestamp, $0) }, uniquingKeysWith: { current, _ in current })
        return uniqueByTimestamp.values.sorted { $0.timestamp < $1.timestamp }
    }

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
        mergedCoreTempData.filter { isWithinSelectedTimeframe($0.timestamp) }
    }

    private var filteredHeartRate: [HeartRatePoint] {
        mergedHeartRateData.filter { isWithinSelectedTimeframe($0.timestamp) }
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
    
    private func convertTemp(_ celsius: Double) -> Double {
        return temperatureUnit == "°F" ? (celsius * 9 / 5) + 32 : celsius
    }

    private func filterAllData() {
        _ = filteredCoreTemp
        _ = filteredHeartRate
        _ = filteredSteps
        _ = filteredCalories
        _ = filteredDistance
    }
}

// MARK: - TrendCard Component
struct TrendCard: View {
    let title: String
    let icon: String
    let color: Color
    let data: [(Date, Double)]
    var yRange: ClosedRange<Double>? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                ZStack {
                    Circle().fill(color.opacity(0.1)).frame(width: 32, height: 32)
                    Image(systemName: icon).foregroundColor(color).font(.system(size: 14, weight: .bold))
                }
                Text(title)
                    .font(.system(.subheadline, design: .rounded))
                    .fontWeight(.bold)
                Spacer()
            }
            
            Group {
                if !data.isEmpty {
                    Chart {
                        ForEach(data.indices, id: \.self) { index in
                            let point = data[index]
                            
                            AreaMark(
                                x: .value("Time", point.0),
                                y: .value("Value", point.1)
                            )
                            .foregroundStyle(
                                .linearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            
                            LineMark(
                                x: .value("Time", point.0),
                                y: .value("Value", point.1)
                            )
                            .foregroundStyle(color)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel()
                                .font(.system(size: 10, design: .rounded))
                        }
                    }
                    .ifLet(yRange) { chart, range in
                        chart.chartYScale(domain: range)
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No data available for this period")
                            .font(.system(.caption, design: .rounded))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
        .padding(20)
        .background(.thinMaterial)
        .cornerRadius(24)
        .padding(.horizontal)
    }
}

extension View {
    @ViewBuilder
    func ifLet<V, Transform: View>(
        _ value: V?,
        transform: (Self, V) -> Transform
    ) -> some View {
        if let value = value {
            transform(self, value)
        } else {
            self
        }
    }
}

