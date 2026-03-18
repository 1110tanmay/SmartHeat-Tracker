import SwiftUI
struct WorkoutSummaryView: View {
    @State private var showWorkout = false
    @State private var showCountdown = false
    @Namespace private var animation

    @EnvironmentObject var workoutManager: WorkoutManager
  
    let timer = Timer.publish(every: 15, on: .main, in: .common).autoconnect()

    var body: some View {
        ZStack {
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.1), Color(red: 0.85, green: 0.2, blue: 0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    Text("SmartHeat Tracker")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 10)

                    workoutTile(
                        icon: "thermometer",
                        title: "Core Temp",
                        value: String(format: "%.2f°C", workoutManager.coreTemp),
                        color: .orange
                    )

                    workoutTile(
                        icon: "heart.fill",
                        title: "Heart Rate",
                        value: "\(Int(workoutManager.heartRate)) BPM",
                        color: .red
                    )

                    Button(action: {
                        withAnimation(.easeInOut) {
                            showCountdown = true
                        }
                    }) {
                        Label("Start Workout", systemImage: "figure.walk")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(RoundedRectangle(cornerRadius: 16).fill(Color.white))
                            .foregroundColor(Color(red: 0.85, green: 0.2, blue: 0.1))
                    }
                    .buttonStyle(PlainButtonStyle())
                    .padding(.top, 4)
                    .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)

                    Spacer(minLength: 10)
                }
                .padding(.horizontal, 16)
                .padding(.top, 20)
                .onAppear {
                    workoutManager.requestAuthorization()
                }
            }
        }

        .fullScreenCover(isPresented: $showCountdown) {
            WorkoutCountdownView(isActive: $showCountdown, startWorkout: $showWorkout)
        }

        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutSessionView()
        }
        .onReceive(timer) { _ in
                   workoutManager.fetchLatestHealthData()
               }
    }
  @ViewBuilder
  func workoutTile(icon: String, title: String, value: String, color: Color) -> some View {
      HStack(alignment: .center, spacing: 12) {
          Image(systemName: icon)
              .foregroundColor(color)
              .font(.system(size: 20))
              .frame(width: 28)

          VStack(alignment: .leading, spacing: 2) {
              Text(title)
                  .font(.caption)
                  .foregroundColor(.white.opacity(0.8))
                  .lineLimit(1)
                  .minimumScaleFactor(0.6)

              Text(value)
                  .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                  .foregroundColor(.white)
                  .lineLimit(1)
                  .minimumScaleFactor(0.5)
          }
          Spacer()
      }
      .padding()
      .frame(maxWidth: .infinity, minHeight: 60)
      .background(
          RoundedRectangle(cornerRadius: 18)
              .fill(Color.white.opacity(0.12)) 
      )
      .cornerRadius(18)
      .shadow(color: color.opacity(0.2), radius: 4, x: 0, y: 2)
  }
}

