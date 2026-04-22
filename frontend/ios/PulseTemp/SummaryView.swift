import SwiftUI
import Charts

struct SummaryView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @StateObject private var profileImageManager = ProfileImageManager.shared
    @AppStorage("temperatureUnit") private var temperatureUnit: String = "°C"
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"

    @State private var firstName: String = "User"
    @State private var wave = false
    @State private var showContent = false // For staggered animation
    @StateObject private var workoutViewModel = WorkoutSummaryViewModel()
    
    // MARK: - Display State (populated via .onReceive to guarantee immediate re-renders)
    @State private var displayHeartRate: String = "..."
    @State private var displayCoreTemp: String = "-"
    @State private var displaySteps: String = "..."
    @State private var displayCalories: String = "..."
    @State private var displayDistance: String = "..."

    // Formats coreTemp based on user's unit preference
    private func formattedCoreTemp(_ ct: Double) -> String {
        let converted = temperatureUnit == "°F" ? (ct * 9 / 5) + 32 : ct
        return String(format: "%.4f %@", converted, temperatureUnit)
    }

    // Formats distance based on user's unit preference
    private func formattedDist(_ d: Double) -> String {
        distanceUnit == "miles"
            ? String(format: "%.2f miles", d * 0.621371)
            : String(format: "%.2f km", d)
    }

    // MARK: - Mock chart for temperature (for now)
    let mockTempTrend: [TemperatureData] = [
        TemperatureData(time: "8AM", temperature: 36.8),
        TemperatureData(time: "10AM", temperature: 37.1),
        TemperatureData(time: "12PM", temperature: 37.2),
        TemperatureData(time: "2PM", temperature: 37.3),
        TemperatureData(time: "4PM", temperature: 37.0)
    ]
    
    // MARK: - Layout Helpers
    private func staggeredAnimation(_ index: Double) -> Animation {
        Animation.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0)
            .delay(0.05 * index)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {

                    // Greeting
                    HStack(spacing: 8) {
                        Text("\(timeBasedGreeting()), \(firstName)")
                            .font(.system(.title2, design: .rounded))
                            .fontWeight(.bold)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                        
                        Text("👋")
                            .font(.title2)
                            .rotationEffect(.degrees(wave ? 12 : -12), anchor: .bottom)
                            .frame(width: 35)
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                    .opacity(showContent ? 1 : 0)
                    .offset(y: showContent ? 0 : 10)

                    // Section: Daily Vitals
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Daily Vitals")
                            .font(.system(.footnote, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .textCase(.uppercase)

                        // Core Temperature
                        NavigationLink(destination: CoreTempDetailView()) {
                            HealthMetricCard(
                                title: "Core Temperature",
                                value: displayCoreTemp,
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
                                                colors: [.orange.opacity(0.4), .orange.opacity(0.1), .clear],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        LineMark(
                                            x: .value("Time", $0.time),
                                            y: .value("Temp", $0.temperature)
                                        )
                                        .interpolationMethod(.catmullRom)
                                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .foregroundStyle(.orange)
                                    }
                                    .chartXAxis(.hidden)
                                    .chartYAxis(.hidden)
                                    .frame(height: 100)
                                    .padding(.top, 10)
                                )
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(staggeredAnimation(1), value: showContent)

                        // Heart Rate
                        NavigationLink(destination: HeartRateDetailView()) {
                            HealthMetricCard(
                                title: "Heart Rate",
                                value: displayHeartRate,
                                icon: "heart.fill",
                                color: .red
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(staggeredAnimation(2), value: showContent)
                    }

                    // Section: Activity & Progress
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Activity & Progress")
                            .font(.system(.footnote, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                            .textCase(.uppercase)

                        // ✅ Replaced Activity Tile with Workout Summary Tile
                        WorkoutSummaryTile(viewModel: workoutViewModel)
                            .opacity(showContent ? 1 : 0)
                            .offset(y: showContent ? 0 : 20)
                            .animation(staggeredAnimation(3), value: showContent)

                        // Calories
                        NavigationLink(destination: CaloriesDetailView()) {
                            HealthMetricCard(
                                title: "Calories Burned",
                                value: displayCalories,
                                icon: "bolt.fill",
                                color: .purple
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(staggeredAnimation(4), value: showContent)

                        // Steps Walked
                        NavigationLink(destination: StepsDetailView()) {
                            HealthMetricCard(
                                title: "Steps Walked",
                                value: displaySteps,
                                icon: "figure.walk",
                                color: .teal
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(staggeredAnimation(5), value: showContent)

                        // Distance Covered
                        NavigationLink(destination: DistanceDetailView().environmentObject(healthKitManager)) {
                            HealthMetricCard(
                                title: "Distance Covered",
                                value: displayDistance,
                                icon: "map.fill",
                                color: .blue
                            )
                        }
                        .opacity(showContent ? 1 : 0)
                        .offset(y: showContent ? 0 : 20)
                        .animation(staggeredAnimation(6), value: showContent)
                    }
                }
                .padding(.vertical)
                // MARK: Reliable re-render listeners — capture into @State to guarantee SwiftUI invalidation
                .onReceive(healthKitManager.$latestHeartRate) { val in
                    displayHeartRate = val.map { "\(Int($0)) BPM" } ?? "..."
                }
                .onReceive(healthKitManager.$latestCoreTemp) { val in
                    displayCoreTemp = val.map { formattedCoreTemp($0) } ?? "-"
                }
                .onReceive(healthKitManager.$latestSteps) { val in
                    displaySteps = val.map { "\($0.formatted()) steps" } ?? "..."
                }
                .onReceive(healthKitManager.$latestCalories) { val in
                    displayCalories = val.map { "\(Int($0)) kcal" } ?? "..."
                }
                .onReceive(healthKitManager.$latestDistance) { val in
                    displayDistance = val.map { formattedDist($0) } ?? "..."
                }
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
                            .overlay(Circle().stroke(Color.primary.opacity(0.1), lineWidth: 1))
                    } else {
                        Image(systemName: "person.crop.circle")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(.blue)
                    }
                }
            }
            .onAppear {
                healthKitManager.fetchAllMetrics()
                workoutViewModel.loadWorkouts()
                if let profile = DatabaseManager.shared.fetchUserProfile() {
                    self.firstName = profile.name
                } else {
                    self.firstName = "User"
                }
                
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    wave = true
                }
                
                // Trigger staggered entrance
                withAnimation(.easeOut(duration: 0.8)) {
                    showContent = true
                }
            }
        }
    }

    // MARK: - Helpers
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

