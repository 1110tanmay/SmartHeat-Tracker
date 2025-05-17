import Foundation
import Combine

class WorkoutSessionManager: ObservableObject {
    @Published var duration: TimeInterval = 0
    @Published var heartRate: Int = 85
    @Published var coreTemp: Double = 37.5
    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var calories: Double = 0

    private var timer: Timer?

    func startWorkout() {
        duration = 0
        steps = 0
        distance = 0
        calories = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.duration += 1
            self.simulateMetrics()
        }
    }

    func pauseWorkout() {
        timer?.invalidate()
        timer = nil
    }

    func resumeWorkout() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.duration += 1
            self.simulateMetrics()
        }
    }

    func endWorkout() {
        timer?.invalidate()
        timer = nil
    }

    private func simulateMetrics() {
        heartRate = Int.random(in: 78...92)
        coreTemp = Double.random(in: 37.2...38.3)
        steps += Int.random(in: 2...4)
        distance += 0.003
        calories += 0.4
    }
}

