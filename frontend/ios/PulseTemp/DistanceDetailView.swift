import SwiftUI
import Charts

struct DistanceDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @AppStorage("distanceUnit") private var distanceUnit: String = "km"
    @State private var timer: Timer?
    
    @State private var isLoading = true

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [Color.blue.opacity(0.15), Color.green.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .scaleEffect(1.5)
                            Text("Mapping your distance...")
                                .font(.system(.subheadline, design: .rounded))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxHeight: .infinity)
                        .padding(.top, 100)
                    } else {
                        let latestDistanceKm = healthKitManager.latestDistance ?? 0.0
                        let latestDistance = distanceUnit == "miles"
                            ? kmToMiles(latestDistanceKm)
                            : latestDistanceKm
                        let distanceData = healthKitManager.distanceTrendData.map { point in
                            (
                                timestamp: point.timestamp,
                                distance: distanceUnit == "miles"
                                    ? kmToMiles(point.distance)
                                    : point.distance
                            )
                        }

                        // HERO Metric Card
                        VStack(spacing: 12) {
                            Text("Total Distance Today")
                                .font(.system(.subheadline, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                            
                            HStack(alignment: .lastTextBaseline, spacing: 4) {
                                Text(String(format: "%.2f", latestDistance))
                                    .font(.system(size: 64, weight: .black, design: .rounded))
                                Text(distanceUnit)
                                    .font(.system(.title3, design: .rounded))
                                    .fontWeight(.bold)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.top, 20)
                        .scaleEffect(showContent ? 1 : 0.9)
                        .opacity(showContent ? 1 : 0)

                        // 📊 Chart Card
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Label("DISTANCE TREND", systemImage: "map.fill")
                                    .font(.system(.caption, design: .rounded))
                                    .fontWeight(.black)
                                    .foregroundColor(.green)
                                Spacer()
                            }
                            
                            if !distanceData.isEmpty {
                                Chart {
                                    ForEach(distanceData, id: \.timestamp) { point in
                                        AreaMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Distance", point.distance)
                                        )
                                        .foregroundStyle(
                                            .linearGradient(
                                                colors: [.green.opacity(0.3), .green.opacity(0.05)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .interpolationMethod(.catmullRom)

                                        LineMark(
                                            x: .value("Time", point.timestamp),
                                            y: .value("Distance", point.distance)
                                        )
                                        .foregroundStyle(.green)
                                        .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))
                                        .interpolationMethod(.catmullRom)
                                    }
                                }
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
                            } else {
                                NoDataPlaceholder()
                            }
                        }
                        .padding(24)
                        .background(.thinMaterial)
                        .cornerRadius(32)
                        .padding(.horizontal)
                        .offset(y: showContent ? 0 : 20)
                        .opacity(showContent ? 1 : 0)

                        // 💡 Insights Card
                        VStack(alignment: .leading, spacing: 12) {
                            Label("DISTANCE INSIGHT", systemImage: "location.fill")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.green)
                            
                            Text("Distance covered reflects your overall range of motion throughout the day. Consistent movement helps maintain metabolic efficiency and thermal balance.")
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
                    }

                    Spacer()
                }
            }
        }
        .navigationTitle("Distance")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            isLoading = true
            healthKitManager.fetchDistanceTrend {
                isLoading = false
            }
            startPolling()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            stopPolling()
        }
    }
    
    func kmToMiles(_ km: Double) -> Double { km * 0.621371 }

    // MARK: - Timer-based Polling
    func startPolling() {
        healthKitManager.fetchLatestDistance()
        
        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchLiveDistance()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
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

struct NoDataPlaceholder: View {
    var body: some View {
        VStack {
            Spacer()
            Text("Gathering movement data...")
                .font(.system(.caption, design: .rounded))
                .foregroundColor(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, minHeight: 150)
    }
}

