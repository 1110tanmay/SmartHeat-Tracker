import SwiftUI

struct WorkoutSummaryReportView: View {
    var totalTime: Int
    var caloriesBurned: Int
    var stepsWalked: Int
    var distance: Double
    var coreTemps: [Double]
    var heartRates: [Int]
    var onDone: () -> Void

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
                    summaryRow(title: "Start Time", value: formattedStartTime())
                    summaryRow(title: "End Time", value: formattedEndTime())
                    summaryRow(title: "Total Time", value: "\(totalTime) sec")
                    summaryRow(title: "Calories Burned", value: "\(caloriesBurned) kcal")
                    summaryRow(title: "Steps Walked", value: "\(stepsWalked)")
                    summaryRow(title: "Distance Walked", value: String(format: "%.2f km", distance))

                    Divider()

                    summaryRow(title: "Lowest Temp", value: String(format: "%.1f°C", coreTemps.min() ?? 0))
                    summaryRow(title: "Highest Temp", value: String(format: "%.1f°C", coreTemps.max() ?? 0))
                    summaryRow(title: "Average Temp", value: String(format: "%.1f°C", average(coreTemps)))

                    Divider()

                    summaryRow(title: "Lowest HR", value: "\(heartRates.min() ?? 0) BPM")
                    summaryRow(title: "Highest HR", value: "\(heartRates.max() ?? 0) BPM")
                    summaryRow(title: "Average HR", value: String(format: "%.0f BPM", average(heartRates)))
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

    func formattedStartTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date().addingTimeInterval(Double(-totalTime)))
    }

    func formattedEndTime() -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: Date())
    }
}

