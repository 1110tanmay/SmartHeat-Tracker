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

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 32) {
                    
                    // 🏃‍♂️ Steps Section
                    VStack(alignment: .leading, spacing: 16) {
                        ActivityHeader(title: "Steps Walked", value: "\(healthKitManager.latestSteps ?? 0)", unit: "steps", icon: "figure.walk", color: .blue)
                        
                        ActivityMiniChart(data: healthKitManager.stepsTrendData.map { ($0.timestamp, Double($0.steps)) }, color: .blue)
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)

                    // 🔥 Calories Section
                    VStack(alignment: .leading, spacing: 16) {
                        ActivityHeader(title: "Calories Burned", value: "\(Int(healthKitManager.latestCalories ?? 0))", unit: "kcal", icon: "flame.fill", color: .red)
                        
                        ActivityMiniChart(data: healthKitManager.caloriesTrendData.map { ($0.timestamp, $0.calories) }, color: .red)
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring().delay(0.1), value: showContent)

                    // 🗺️ Distance Section
                    VStack(alignment: .leading, spacing: 16) {
                        let latestDistanceKm = healthKitManager.latestDistance ?? 0.0
                        let latestDistance = distanceUnit == "miles" ? kmToMiles(latestDistanceKm) : latestDistanceKm
                        
                        ActivityHeader(title: "Distance Traveled", value: String(format: "%.2f", latestDistance), unit: distanceUnit, icon: "map.fill", color: .green)
                        
                        ActivityMiniChart(data: convertedDistanceTrend.map { ($0.timestamp, $0.distance) }, color: .green)
                    }
                    .padding(20)
                    .background(.thinMaterial)
                    .cornerRadius(24)
                    .padding(.horizontal)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 20)
                    .animation(.spring().delay(0.2), value: showContent)

                    Spacer()
                }
            }
        }
        .navigationTitle("Activity")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            startPolling()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
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
            let point = CaloriePoint(timestamp: now, calories: calories)
            if healthKitManager.caloriesTrendData.last?.timestamp != point.timestamp {
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

// MARK: - Premium UI Components

struct ActivityHeader: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.1)).frame(width: 40, height: 40)
                Image(systemName: icon).foregroundColor(color).font(.headline)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                HStack(alignment: .lastTextBaseline, spacing: 4) {
                    Text(value)
                        .font(.system(.title2, design: .rounded))
                        .fontWeight(.black)
                    Text(unit)
                        .font(.system(.caption, design: .rounded))
                        .fontWeight(.bold)
                        .foregroundColor(.secondary)
                }
            }
            Spacer()
        }
    }
}

struct ActivityMiniChart: View {
    let data: [(Date, Double)]
    let color: Color
    
    var body: some View {
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
        .chartYAxis(.hidden)
        .frame(height: 100)
    }
}

