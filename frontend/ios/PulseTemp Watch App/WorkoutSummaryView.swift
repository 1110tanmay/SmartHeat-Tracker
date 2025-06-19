import SwiftUI

struct WorkoutSummaryView: View {
    @State private var showWorkout = false
    @State private var showCountdown = false
    @Namespace private var animation

    @EnvironmentObject var workoutManager: WorkoutManager

    var body: some View {
        ZStack {
            // Background Gradient
            LinearGradient(
                gradient: Gradient(colors: [.black, .green.opacity(0.7)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .edgesIgnoringSafeArea(.all)

            ScrollView {
                VStack(spacing: 28) {
                    Text("SmartHeat Tracker")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.green)

                    // Core Temp (still mock until WatchConnectivity sync)
                  workoutTile(
                      icon: "thermometer",
                      title: "Core Temp",
                      value: String(format: "%.2f°C", workoutManager.coreTemp),
                      color: .orange
                  )

                    // Real-time heart rate from WorkoutManager
                    workoutTile(icon: "heart.fill", title: "Heart Rate", value: "\(Int(workoutManager.heartRate)) BPM", color: .red)

                    // Start Workout Button
                    Button(action: {
                        withAnimation(.easeInOut) {
                            showCountdown = true
                        }
                    }) {
                        Label("Start Workout", systemImage: "figure.walk")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14).fill(Color.green))
                            .foregroundColor(.black)
                    }
                    .buttonStyle(PlainButtonStyle())
                    .shadow(color: Color.green.opacity(0.4), radius: 6, x: 0, y: 3)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .onAppear {
                    workoutManager.requestAuthorization() // ✅ Keep only this
                }
            }
        }
        // Show Countdown First
        .fullScreenCover(isPresented: $showCountdown) {
            WorkoutCountdownView(isActive: $showCountdown, startWorkout: $showWorkout)
        }

        // After Countdown Completes → Start Workout
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutSessionView()
        }
    }

    @ViewBuilder
    func workoutTile(icon: String, title: String, value: String, color: Color) -> some View {
        HStack(alignment: .center, spacing: 16) {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.system(size: 28))
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(Color.black.opacity(0.35))
        .cornerRadius(18)
        .shadow(color: color.opacity(0.3), radius: 6, x: 0, y: 3)
    }
}

