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

    @State private var showContent = false

    var body: some View {
        ZStack {
            // Premium Background
            LinearGradient(
                colors: [Color.red.opacity(0.15), Color.pink.opacity(0.1), Color.white],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    
                    // HERO Metric Card
                    VStack(spacing: 12) {
                        Text("Current Heart Rate")
                            .font(.system(.subheadline, design: .rounded))
                            .fontWeight(.bold)
                            .foregroundColor(.secondary)
                        
                        Text(latestHeartRate)
                            .font(.system(size: 54, weight: .black, design: .rounded))
                            .foregroundColor(.primary)
                    }
                    .padding(.top, 20)
                    .scaleEffect(showContent ? 1 : 0.9)
                    .opacity(showContent ? 1 : 0)

                    // 📊 Chart Card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Label("HR TREND", systemImage: "heart.text.square.fill")
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.black)
                                .foregroundColor(.red)
                            Spacer()
                            Text(heartRateRange)
                                .font(.system(.caption, design: .rounded))
                                .fontWeight(.bold)
                                .foregroundColor(.secondary)
                        }
                        
                        Chart {
                            ForEach(healthKitManager.heartRateData) { point in
                                AreaMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("BPM", point.bpm)
                                )
                                .foregroundStyle(
                                    .linearGradient(
                                        colors: [.red.opacity(0.3), .red.opacity(0.05)],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .interpolationMethod(.catmullRom)

                                LineMark(
                                    x: .value("Time", point.timestamp),
                                    y: .value("BPM", point.bpm)
                                )
                                .foregroundStyle(.red)
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
                    }
                    .padding(24)
                    .background(.thinMaterial)
                    .cornerRadius(32)
                    .padding(.horizontal)
                    .offset(y: showContent ? 0 : 20)
                    .opacity(showContent ? 1 : 0)

                    // 💡 Insights Card
                    VStack(alignment: .leading, spacing: 12) {
                        Label("CARDIAC INSIGHT", systemImage: "heart.circle.fill")
                            .font(.system(.caption, design: .rounded))
                            .fontWeight(.black)
                            .foregroundColor(.red)
                        
                        Text("Heart rate is a primary indicator of your cardiovascular exertion and thermal stress. Tracking your BPM helps in accurate core body temperature estimation.")
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
        .navigationTitle("Heart Rate")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            healthKitManager.fetchLatestHeartRateAndUpdateCoreTemp()
            startTimer()
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                showContent = true
            }
        }
        .onDisappear {
            stopTimer()
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
