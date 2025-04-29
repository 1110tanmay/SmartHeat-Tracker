import SwiftUI

struct WorkoutSummaryView: View {
    @State private var showWorkout = false

    var body: some View {
        VStack(spacing: 20) {
            // 🌡️ Core Temp Tile
            Text("🌡️ Core Temperature: -- °C")
                .font(.headline)

            // ❤️ Heart Rate Tile
            Text("❤️ Heart Rate: -- BPM")
                .font(.headline)

            // 🚀 Start Workout Button
            Button(action: {
                showWorkout = true
            }) {
                Text("Start Workout")
                    .padding()
                    .background(Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .fullScreenCover(isPresented: $showWorkout) {
            WorkoutSessionView()
        }
    }
}

#Preview {
    WorkoutSummaryView()
}

