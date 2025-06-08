import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var workoutManager: WorkoutManager

    @State private var isPaused = false
    @State private var showSummary = false

    // Tracking for summary
    @State private var tempSamples: [Double] = []
    @State private var heartRateSamples: [Int] = []

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
                        Text(String(format: "%02d:%02d", Int(workoutManager.elapsedTime) / 60, Int(workoutManager.elapsedTime) % 60))
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.yellow)
                            .monospacedDigit()
                            .padding(.top)

                        // Metric Rings
                        HStack(spacing: 16) {
                            metricRing(title: "CAL", value: workoutManager.activeEnergy, color: .red)
                            metricRing(title: "STEPS", value: Double(estimateSteps(from: workoutManager.distance)), color: .green)
                            metricRing(title: "KM", value: workoutManager.distance, color: .blue)
                        }
                        .padding(.horizontal)

                        // Temp & HR (core temp is still mock for now)
                        VStack(spacing: 6) {
                            HStack {
                                Text("🌡️ Core Temp:")
                                Spacer()
                                Text("~37.5°C") // Placeholder until we sync from phone
                            }
                            HStack {
                                Text("❤️ Heart Rate:")
                                Spacer()
                                Text("\(Int(workoutManager.heartRate)) BPM")
                            }
                        }
                        .padding(.horizontal)
                        .foregroundColor(.white)

                        // Action buttons
                        HStack(spacing: 16) {
                            Button(action: {
                                isPaused.toggle()
                                isPaused ? workoutManager.pauseWorkout() : workoutManager.resumeWorkout()
                            }) {
                                Label(isPaused ? "Resume" : "Pause", systemImage: "pause.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16).fill(Color.yellow)
                                    )
                                    .foregroundColor(.black)
                            }

                            Button(action: {
                                workoutManager.endWorkout()
                                showSummary = true
                            }) {
                                Label("End", systemImage: "xmark.circle.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16).fill(Color.red)
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
                workoutManager.startWorkout()
            }
            .navigationDestination(isPresented: $showSummary) {
                WorkoutSummaryReportView(
                    totalTime: Int(workoutManager.elapsedTime),
                    caloriesBurned: Int(workoutManager.activeEnergy),
                    stepsWalked: estimateSteps(from: workoutManager.distance),
                    distance: workoutManager.distance,
                    coreTemps: tempSamples, // will update later
                    heartRates: heartRateSamples,
                    onDone: {
                        presentationMode.wrappedValue.dismiss()
                    }
                )
            }
        }
    }

    func estimateSteps(from km: Double) -> Int {
        return Int((km * 1000) / 0.762) // average stride length ≈ 76.2cm
    }

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

