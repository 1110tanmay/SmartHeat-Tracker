import SwiftUI
import WatchKit

struct WorkoutSummaryReportView: View {
    var totalTime: Int
    var caloriesBurned: Int
    var stepsWalked: Int
    var distance: Double
    var coreTemps: [Double]
    var heartRates: [Int]
    var onDone: () -> Void

    var body: some View {
        ZStack {
            // 🔥 Consistent Brand Gradient
            LinearGradient(
                gradient: Gradient(colors: [Color(red: 1.0, green: 0.6, blue: 0.1), Color(red: 0.85, green: 0.2, blue: 0.1)]),
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    Text("Workout Summary")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .padding(.top, 16)

                    summaryTile(icon: "clock", title: "Total Time", value: "\(totalTime) sec")
                    summaryTile(icon: "flame", title: "Calories Burned", value: "\(caloriesBurned) kcal")
                    summaryTile(icon: "figure.walk", title: "Steps Walked", value: "\(stepsWalked)")
                    summaryTile(icon: "map", title: "Distance Walked", value: String(format: "%.2f km", distance))

                    Divider().opacity(0.2)

                    summaryTile(icon: "thermometer", title: "Lowest Temp", value: String(format: "%.1f°C", coreTemps.min() ?? 0))
                    summaryTile(icon: "thermometer", title: "Highest Temp", value: String(format: "%.1f°C", coreTemps.max() ?? 0))
                    summaryTile(icon: "thermometer", title: "Average Temp", value: String(format: "%.1f°C", average(coreTemps)))

                    Divider().opacity(0.2)

                    summaryTile(icon: "heart.fill", title: "Lowest HR", value: "\(heartRates.min() ?? 0) BPM")
                    summaryTile(icon: "heart.fill", title: "Highest HR", value: "\(heartRates.max() ?? 0) BPM")
                    summaryTile(icon: "heart.fill", title: "Average HR", value: String(format: "%.0f BPM", average(heartRates)))

                    Spacer(minLength: 12)

                  Button(action: {
                      onDone()
                  }) {
                      Label("Done", systemImage: "checkmark")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(Color(red: 0.85, green: 0.2, blue: 0.1))
                          .frame(maxWidth: .infinity)
                          .padding(.vertical, 10)
                          .background(
                              RoundedRectangle(cornerRadius: 18)
                                  .fill(Color.white)
                          )
                  }
                  .buttonStyle(PlainButtonStyle())
                  .shadow(color: Color.black.opacity(0.15), radius: 3, x: 0, y: 2)
                  .padding(.horizontal, 16)
                  .padding(.bottom, 24)
                }
                .frame(minHeight: WKInterfaceDevice.current().screenBounds.height)
                .padding(.horizontal, 16)
            }
        }
    }

    // MARK: - UI Components
    func summaryTile(icon: String, title: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.yellow)
                .font(.system(size: 16))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.8))
                Text(value)
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 60)
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white.opacity(0.12))
        )
    }

    // MARK: - Helpers
    func average<T: BinaryFloatingPoint>(_ values: [T]) -> T {
        guard !values.isEmpty else { return 0 }
        return values.reduce(0, +) / T(values.count)
    }

    func average(_ values: [Int]) -> Double {
        guard !values.isEmpty else { return 0 }
        return Double(values.reduce(0, +)) / Double(values.count)
    }
}

