import SwiftUI
import Charts

struct SummaryView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var profileImageManager = ProfileImageManager.shared
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

    @State private var firstName: String = "User"
    @State private var wave = false
    @StateObject private var workoutViewModel = WorkoutSummaryViewModel()
    // MARK: - Computed Properties
    var heartRate: Int {
        Int(healthKitManager.latestHeartRate ?? 75)
    }

    var steps: Int {
        Int(healthKitManager.latestSteps ?? 8500)
    }

    var calories: Int {
        Int(healthKitManager.latestCalories ?? 410)
    }

    var distanceKm: Double {
        healthKitManager.latestDistance ?? 4.5
    }

    var coreTemp: String {
        guard let ct = healthKitManager.latestCoreTemp else {
            return "-"
        }

        let converted = temperatureUnit == "°F"
            ? (ct * 9 / 5) + 32
            : ct

        return String(format: "%.4f %@", converted, temperatureUnit)
    }

    // MARK: - Mock chart for temperature (for now)
    let mockTempTrend: [TemperatureData] = [
        TemperatureData(time: "8AM", temperature: 36.8),
        TemperatureData(time: "10AM", temperature: 37.1),
        TemperatureData(time: "12PM", temperature: 37.2),
        TemperatureData(time: "2PM", temperature: 37.3),
        TemperatureData(time: "4PM", temperature: 37.0)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    // Greeting
                    HStack(spacing: 4) {
                        Text("\(timeBasedGreeting()), \(firstName)")
                            .font(.title2)
                            .fontWeight(.semibold)

                        Text("👋")
                            .font(.title2)
                            .rotationEffect(.degrees(wave ? 3 : -3))
                            .animation(Animation.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: wave)
                    }
                    .padding(.horizontal)

                    // Core Temperature
                    NavigationLink(destination: CoreTempDetailView()) {
                        HealthMetricCard(
                            title: "Core Temperature",
                            value: coreTemp,
                            icon: "thermometer",
                            color: .orange,
                            isLarge: true,
                            trailingView: AnyView(
                                Chart(mockTempTrend) {
                                    AreaMark(
                                        x: .value("Time", $0.time),
                                        y: .value("Temp", $0.temperature)
                                    )
                                    .foregroundStyle(
                                        .linearGradient(
                                            colors: [.orange.opacity(0.3), .clear],
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                    )
                                    LineMark(
                                        x: .value("Time", $0.time),
                                        y: .value("Temp", $0.temperature)
                                    )
                                    .interpolationMethod(.monotone)
                                    .foregroundStyle(.orange)
                                }
                                .chartXAxis(.hidden)
                                .chartYAxis(.hidden)
                                .frame(height: 100)
                            )
                        )
                    }

                    // Heart Rate
                    NavigationLink(destination: HeartRateDetailView()) {
                        HealthMetricCard(
                            title: "Heart Rate",
                            value: "\(heartRate) BPM",
                            icon: "heart.fill",
                            color: .red
                        )
                    }

                    // ✅ Replaced Activity Tile with Workout Summary Tile
                    WorkoutSummaryTile(viewModel: workoutViewModel)

                    // Calories
                    NavigationLink(destination: CaloriesDetailView()) {
                        HealthMetricCard(
                            title: "Calories Burned",
                            value: "\(calories) kcal",
                            icon: "bolt.fill",
                            color: .purple
                        )
                    }

                    // Steps Walked
                    NavigationLink(destination: StepsDetailView()) {
                        HealthMetricCard(
                            title: "Steps Walked",
                            value: "\(steps.formatted()) steps",
                            icon: "figure.walk",
                            color: .teal
                        )
                    }

                    // Distance Covered
                    NavigationLink(destination: DistanceDetailView().environmentObject(healthKitManager)) {
                        HealthMetricCard(
                            title: "Distance Covered",
                            value: formattedDistance(distanceKm),
                            icon: "map.fill",
                            color: .blue
                        )
                    }
                }
                .padding(.vertical)
                .onReceive(healthKitManager.$latestSteps) { _ in }
                .onReceive(healthKitManager.$latestCalories) { _ in }
                .onReceive(healthKitManager.$latestDistance) { _ in }
            }
            .navigationTitle("Summary")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if let image = ProfileImageManager.shared.profileImage {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: 36, height: 36)
                            .clipShape(Circle())
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                healthKitManager.fetchAllMetrics()
                workoutViewModel.loadWorkouts()  // ✅ Add this line
                if let profile = DatabaseManager.shared.fetchUserProfile() {
                    self.firstName = profile.name
                } else {
                    self.firstName = "User"
                }
                wave = true
            }
        }
    }

    // MARK: - Helpers
    func formattedDistance(_ km: Double) -> String {
        if distanceUnit == "miles" {
            let miles = km * 0.621371
            return String(format: "%.2f miles", miles)
        } else {
            return String(format: "%.2f km", km)
        }
    }

    func timeBasedGreeting() -> String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Good Morning"
        case 12..<17: return "Good Afternoon"
        case 17..<22: return "Good Evening"
        default: return "Hello"
        }
    }
}

struct TemperatureData: Identifiable {
    let id = UUID()
    let time: String
    let temperature: Double
}

