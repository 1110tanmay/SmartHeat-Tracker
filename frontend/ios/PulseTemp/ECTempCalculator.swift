import Foundation

class ECTempCalculator: ObservableObject {
    
    // MARK: - Sigmoid Function Parameters (from Looney et al., 2018)
    private let A: Double = 41        // Lower asymptote of HR
    private let K: Double = 152       // Upper asymptote of HR
    private let Q: Double = 0.06      // Scaling factor
    private let beta: Double = 0.89   // Growth rate
    private let M: Double = 37.84     // Midpoint of sigmoid
    private let v: Double = 0.07      // Shape parameter

    // MARK: - Kalman Filter Variables
    @Published var estimatedCT: Double = 37.0  // Initial core temperature estimate (°C)
    private var variance: Double = 0.02        // Initial variance (uncertainty)
    private var hrObservations: [Double] = []  // Optional HR history (for trend display)

    // MARK: - Predict HR given a CT (Forward Sigmoid)
    private func predictedHR(ct: Double) -> Double {
        let numerator = K - A
        let denominator = pow(1 + Q * exp(-beta * (ct - M)), 1 / v)
        return A + numerator / denominator
    }

    // MARK: - Estimate CT from HR by inverting the sigmoid
    private func computeCoreTemp(from heartRate: Double) -> Double {
        guard heartRate >= A && heartRate <= K else {
            return estimatedCT
        }

        let term = pow((K - A) / (heartRate - A), v) - 1
        let logInput = term / Q

        guard logInput > 0 else {
            print("⚠️ logInput non-positive → fallback to previous CT")
            return estimatedCT
        }

        return M - log(logInput) / beta
    }

    // MARK: - Kalman Filter Update for Smoothing
    func updateCoreTemp(with heartRate: Double) -> Double {
        let computedCT = computeCoreTemp(from: heartRate)
        let predictedCT = estimatedCT
        let predictedVariance = variance + 0.000484  // ← from paper

        let predictedHRValue = predictedHR(ct: predictedCT)

        var m = (-beta * (K - A) * v * pow(max(predictedHRValue - A, 1), -1 - v)) /
                pow(1 + Q * exp(-beta * (predictedCT - M)), 1 / v)

        if abs(m) < 1e-6 {
            m = 1e-6
        }

        var kalmanGain = (predictedVariance * m) /
                         (pow(m, 2) * predictedVariance + 356.4544)
        kalmanGain = min(1, max(0.0001, kalmanGain))

        estimatedCT = predictedCT + kalmanGain * (heartRate - predictedHRValue)
        variance = (1 - kalmanGain * m) * predictedVariance

        hrObservations.append(heartRate)
        if hrObservations.count > 60 {
            hrObservations.removeFirst()
        }

        print("HR: \(heartRate) | Computed CT: \(computedCT) | Final CT: \(estimatedCT) | Kalman Gain: \(kalmanGain)")
        return estimatedCT
    }

    // MARK: - Optional: Return HR Trend History (if needed)
    func getHRHistory() -> [Double] {
        return hrObservations
    }
}

