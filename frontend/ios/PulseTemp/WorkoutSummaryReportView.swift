import SwiftUI

struct WorkoutSummaryReportView: View {
    var workout: WorkoutSession
    var onDone: () -> Void

    // New initializer to support live values from WorkoutSessionView
  init(workout: WorkoutSession, onDone: @escaping () -> Void) {
      self.workout = workout
      self.onDone = onDone
  }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Title
                Text("Workout Summary")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                    .foregroundColor(.primary)

                VStack(spacing: 12) {
                    summaryRow(title: "Start Time", value: formattedTime(workout.startTime))
                    summaryRow(title: "End Time", value: formattedTime(workout.endTime))

                    summaryRow(title: "Calories Burned", value: "\(Int(workout.totalCalories)) kcal")
                    summaryRow(title: "Steps Walked", value: "\(workout.totalSteps)")
                    summaryRow(title: "Distance Walked", value: String(format: "%.2f km", workout.totalDistance))

                    Divider()

                    summaryRow(title: "Lowest Temp", value: String(format: "%.2f°C", workout.coreTempMin))
                    summaryRow(title: "Average Temp", value: String(format: "%.2f°C", workout.coreTempAvg))
                    summaryRow(title: "Highest Temp", value: String(format: "%.2f°C", workout.coreTempMax))

                    Divider()

                    summaryRow(title: "Lowest HR", value: "\(workout.heartRateMin) BPM")
                    summaryRow(title: "Average HR", value: "\(workout.heartRateAvg) BPM")
                    summaryRow(title: "Highest HR", value: "\(workout.heartRateMax) BPM")
                }
                .padding(.horizontal)
                .background(RoundedRectangle(cornerRadius: 16).fill(Color(.systemGray6)))
                .padding(.horizontal)

                Button(action: onDone) {
                    Text("Done")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
            }
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground).ignoresSafeArea())
    }

    // MARK: - Helpers

    func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .foregroundColor(.primary)
        }
        .padding(.horizontal)
    }

    func average<T: BinaryFloatingPoint>(_ values: [T]) -> T {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / T(values.count)
    }

    func average(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }

    func formattedTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

