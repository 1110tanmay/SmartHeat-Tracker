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
            ZStack {
                LinearGradient(
                    gradient: Gradient(colors: [.black, .green.opacity(0.6)]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .edgesIgnoringSafeArea(.all)

                VStack(spacing: 16) {
                    Text("Workout Summary")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(.green)
                        .padding(.top)

                    summaryRow(title: "Total Time", value: "\(totalTime) sec")
                    summaryRow(title: "Calories Burned", value: "\(caloriesBurned) kcal")
                    summaryRow(title: "Steps Walked", value: "\(stepsWalked)")
                    summaryRow(title: "Distance Walked", value: String(format: "%.2f km", distance))

                    Divider()
                        .background(Color.white)

                    summaryRow(title: "Lowest Temp", value: String(format: "%.1f°C", coreTemps.min() ?? 0))
                    summaryRow(title: "Highest Temp", value: String(format: "%.1f°C", coreTemps.max() ?? 0))
                    summaryRow(title: "Average Temp", value: String(format: "%.1f°C", average(coreTemps)))

                    Divider()
                        .background(Color.white)

                    summaryRow(title: "Lowest HR", value: "\(heartRates.min() ?? 0) BPM")
                    summaryRow(title: "Highest HR", value: "\(heartRates.max() ?? 0) BPM")
                    summaryRow(title: "Average HR", value: String(format: "%.0f BPM", average(heartRates)))

                  Button(action: {
                      onDone()
                  }) {
                      Text("Done")
                          .font(.headline)
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 10)
                          .background(Color.blue)
                          .foregroundColor(.white)
                          .cornerRadius(14)
                          .padding(.horizontal)
                  }

                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
        }
    }

    func summaryRow(title: String, value: String) -> some View {
        HStack {
            Text(title + ":")
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.white)
        }
        .font(.system(size: 16, weight: .medium))
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
}

#Preview {
    WorkoutSummaryReportView(
        totalTime: 300,
        caloriesBurned: 120,
        stepsWalked: 1000,
        distance: 0.85,
        coreTemps: [37.2, 37.5, 37.6],
        heartRates: [80, 83, 85],
        onDone: {}
    )
}

