import SwiftUI

struct WorkoutSessionView: View {
    @Environment(\.presentationMode) var presentationMode
    @State private var isPaused = false
    @State private var workoutDuration: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                Text("Workout In Progress")
                    .font(.headline)

                Text("⏱ Time: \(Int(workoutDuration)) sec")
                Text("🌡️ Core Temp: 37.5°C")
                Text("❤️ Heart Rate: 85 BPM")
                Text("👟 Steps: 0")
                Text("📏 Distance: 0.0 km")
                Text("🔥 Calories: 0 kcal")

                HStack {
                    Button(action: {
                        isPaused.toggle()
                        if isPaused {
                            timer?.invalidate()
                        } else {
                            startTimer()
                        }
                    }) {
                        Text(isPaused ? "Resume" : "Pause")
                            .padding()
                            .background(Color.orange)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        timer?.invalidate()
                        presentationMode.wrappedValue.dismiss()
                    }) {
                        Text("End Workout")
                            .padding()
                            .background(Color.red)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
                .padding(.top)
            }
            .padding()
            .onAppear {
                startTimer()
            }
        }
    }

    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            workoutDuration += 1
        }
    }
}

#Preview {
    WorkoutSessionView()
}

