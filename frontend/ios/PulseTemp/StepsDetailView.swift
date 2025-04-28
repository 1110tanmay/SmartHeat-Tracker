import SwiftUI
import Charts

struct StepsDetailView: View {
    @EnvironmentObject var healthKitManager: HealthKitManager
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
              
              // Title
              Text("Steps walked today:")
                  .font(.largeTitle)
                  .fontWeight(.bold)

                // Steps Range
                VStack {
                    Text("RANGE")
                        .font(.caption)
                        .foregroundColor(.gray)

                    if let min = healthKitManager.stepsTrendData.map(\.steps).min(),
                       let max = healthKitManager.stepsTrendData.map(\.steps).max() {
                        Text("\(min.formatted()) - \(max.formatted()) steps")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    } else {
                        Text("-")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                    }
                }
                
              
                // Steps Chart
                if !healthKitManager.stepsTrendData.isEmpty {
                    Chart {
                        ForEach(healthKitManager.stepsTrendData) { point in
                            LineMark(
                                x: .value("Time", point.timestamp),
                                y: .value("Steps", point.steps)
                            )
                            .foregroundStyle(
                                point.id == healthKitManager.stepsTrendData.last?.id
                                ? Color.green
                                : Color.teal
                            )
                        }
                    }
                    .frame(height: 200)
                    .padding()
                } else {
                    Text("No step data available.")
                        .foregroundColor(.gray)
                        .padding()
                }

                // Latest Steps
                if let steps = healthKitManager.latestSteps {
                    VStack {
                        Text("Latest: \(currentTime())")
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                        Text("\(steps.formatted()) steps")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.green)
                    .cornerRadius(12)
                }

                Spacer()
            }
            .padding()
        }
        .navigationTitle("Steps Walked")
        .onAppear {
          healthKitManager.fetchStepsTrend()
            startPolling()
        }
        .onDisappear {
            stopPolling()
        }
    }

    // MARK: - Helpers
    func currentTime() -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }

    func startPolling() {
        fetchLiveSteps()

        timer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { _ in
            fetchLiveSteps()
        }
    }

    func stopPolling() {
        timer?.invalidate()
        timer = nil
    }

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
}

