import Foundation

class ECTempCalculator: ObservableObject {
    
    // MARK: - Sigmoid Function Parameters (from Looney et al., 2018)
    private let A: Double = 41
    private let K: Double = 152
    private let Q: Double = 0.06
    private let beta: Double = 0.89
    private let M: Double = 37.84
    private let v: Double = 0.07

    // MARK: - Kalman Filter Variables
    @Published var estimatedCT: Double = 37.0  // Initial core temperature (°C)
    private var variance: Double = 0.01        // Initial variance
    private var hrObservations: [Double] = []

    // MARK: - Sigmoid Forward Mapping (Equation 8)
    private func predictedHR(ct: Double) -> Double {
        let numerator = K - A
        let denominator = pow(1 + Q * exp(-beta * (ct - M)), 1 / v)
        return A + numerator / denominator
    }

    // MARK: - Kalman Filter Update (Equations 2, 4, 5, 6)
    func updateCoreTemp(with heartRate: Double) -> Double {
        let predictedCT = estimatedCT
        let predictedVariance = variance + 0.000484  // Equation 2

        let predictedHRValue = predictedHR(ct: predictedCT)

        // Equation 9 - Mapping slope m_t
        let expTerm = exp(-beta * (predictedCT - M))
        let mNumerator = 8.1168 * expTerm * pow(0.06 * expTerm + 1, -15.2857)
        let m = mNumerator / 0.07

        // Equation 4 - Kalman Gain
        let kalmanGain = (predictedVariance * m) / (pow(m, 2) * predictedVariance + 356.4544)

        // Equation 5 - CT update
        estimatedCT = predictedCT + kalmanGain * (heartRate - predictedHRValue)

        // Equation 6 - Variance update
        variance = (1 - kalmanGain * m) * predictedVariance

        hrObservations.append(heartRate)
        if hrObservations.count > 60 {
            hrObservations.removeFirst()
        }

        print("HR: \(heartRate) | Final CT: \(estimatedCT) | Kalman Gain: \(kalmanGain)")
        return estimatedCT
    }

    // MARK: - Optional HR History
    func getHRHistory() -> [Double] {
        return hrObservations
    }
}

