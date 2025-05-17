import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isPaused = false
    @State private var workoutDuration: TimeInterval = 0
    @State private var timer: Timer?

    // Simulated live metrics
    @State private var caloriesBurned: Int = 13
    @State private var stepsWalked: Int = 26
    @State private var distance: Double = 0.0
    @State private var coreTemp: Double = 37.6
    @State private var heartRate: Int = 83

    // Workout tracking samples
    @State private var tempSamples: [Double] = []
    @State private var heartRateSamples: [Int] = []
    @State private var showSummary = false

    var body: some View {
        NavigationStack {
            ScrollView {
                ZStack {
                    LinearGradient(
                        gradient: Gradient(colors: [.black, .green.opacity(0.6)]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .edgesIgnoringSafeArea(.all)

                    VStack(spacing: 16) {
                        // Timer
                        Text(String(format: "%02d:%02d", Int(workoutDuration) / 60, Int(workoutDuration) % 60))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.yellow)
                            .monospacedDigit()
                            .padding(.top)

                        // Metric rings
                        HStack(spacing: 16) {
                            metricRing(title: "CAL", value: Double(caloriesBurned), color: .red)
                            metricRing(title: "STEPS", value: Double(stepsWalked), color: .green)
                            metricRing(title: "KM", value: distance, color: .blue)
                        }
                        .padding(.horizontal)

                        // Temperature & HR
                        VStack(spacing: 6) {
                            HStack {
                                Text("🌡️ Core Temp:")
                                Spacer()
                                Text(String(format: "%.1f°C", coreTemp))
                            }
                            HStack {
                                Text("❤️ Heart Rate:")
                                Spacer()
                                Text("\(heartRate) BPM")
                            }
                        }
                        .padding(.horizontal)
                        .foregroundColor(.white)

                        // Action buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                isPaused.toggle()
                                if isPaused {
                                    timer?.invalidate()
                                } else {
                                    startTimer()
                                }
                            }) {
                                Label(isPaused ? "Resume" : "Pause", systemImage: "pause.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.yellow)
                                    )
                                    .foregroundColor(.black)
                            }

                            Button(action: {
                                timer?.invalidate()
                                showSummary = true
                            }) {
                                Label("End", systemImage: "xmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.red)
                                    )
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                    .padding(.top)
                }
            }
            .onAppear {
                startTimer()
            }
            .navigationDestination(isPresented: $showSummary) {
              WorkoutSummaryReportView(
                  totalTime: Int(workoutDuration),
                  caloriesBurned: caloriesBurned,
                  stepsWalked: stepsWalked,
                  distance: distance,
                  coreTemps: tempSamples,
                  heartRates: heartRateSamples,
                  onDone: {
                      presentationMode.wrappedValue.dismiss()
                  }
              )

            }
        }
    }

    // MARK: - Timer
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            workoutDuration += 1
            coreTemp = 37.5 + Double.random(in: -0.2...0.3)
            heartRate = 80 + Int.random(in: 0...8)

            caloriesBurned += 1
            stepsWalked += 2
            distance += 0.01

            tempSamples.append(coreTemp)
            heartRateSamples.append(heartRate)
        }
    }

    // MARK: - Ring View
    func metricRing(title: String, value: Double, color: Color) -> some View {
        VStack {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.2), lineWidth: 10)
                    .frame(width: 50, height: 50)
                Circle()
                    .trim(from: 0, to: min(value / 100.0, 1.0))
                    .stroke(color, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .frame(width: 50, height: 50)
                Text(String(format: "%.0f", value))
                    .font(.footnote)
                    .foregroundColor(.white)
            }
            Text(title)
                .font(.caption2)
                .foregroundColor(color)
        }
    }
}

#Preview {
    WorkoutSessionView()
}
