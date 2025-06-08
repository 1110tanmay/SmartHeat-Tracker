
import Foundation
import Combine
import WatchConnectivity

class WorkoutSessionManager: NSObject, ObservableObject, WCSessionDelegate {
    @Published var duration: TimeInterval = 0
    @Published var heartRate: Int = 0
    @Published var coreTemp: Double = 0.0
    @Published var steps: Int = 0
    @Published var distance: Double = 0
    @Published var calories: Double = 0

    private var timer: Timer?

    override init() {
        super.init()
        setupWatchConnectivity()
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("🔁 WatchConnectivity activated in WorkoutSessionManager")
        }
    }

    func startWorkout() {
        duration = 0
        steps = 0
        distance = 0
        calories = 0

        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.duration += 1
            self.updateMetrics()
        }
    }

    func pauseWorkout() {
        timer?.invalidate()
        timer = nil
    }

    func resumeWorkout() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.duration += 1
            self.updateMetrics()
        }
    }

    func endWorkout() {
        timer?.invalidate()
        timer = nil
    }

    private func updateMetrics() {
        // These will be dynamically updated via WatchConnectivity now.
        steps += Int.random(in: 2...4)
        distance += 0.003
        calories += 0.4
    }

    // MARK: - WatchConnectivity Delegate
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let hr = message["heartRate"] as? Double {
                self.heartRate = Int(hr)
            }
            if let temp = message["coreTemp"] as? Double {
                self.coreTemp = temp
            }
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("🛑 WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ WCSession activated with state: \(activationState.rawValue)")
        }
    }
}
