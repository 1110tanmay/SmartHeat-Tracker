import Foundation
import WatchConnectivity

class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WatchConnectivityManager()
    private var timer: Timer?
    
  // ✅ Add these to make values observable in SwiftUI views
     @Published var heartRate: Double = 0.0
     @Published var coreTemp: Double = 0.0
  
    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - Start Sending Sensor Data
    func startSendingSensorData() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { _ in
            self.sendLiveSensorData()
        }
    }

    // MARK: - Stop Sending Sensor Data
    func stopSendingSensorData() {
        timer?.invalidate()
        timer = nil
    }

    // MARK: - Send Live Sensor Data to Watch
  // MARK: - Send Live Sensor Data to Watch
  private func sendLiveSensorData() {
      let timestamp = Date()

      // ✅ Send heart rate only if valid
      if let heartRate = HealthKitManager.shared.latestHeartRate {
          DatabaseManager.shared.insertHeartRatePoint(HeartRatePoint(timestamp: timestamp, bpm: heartRate))
          DispatchQueue.main.async { self.heartRate = heartRate }

          if WCSession.default.isReachable {
              WCSession.default.sendMessage(["heartRate": heartRate], replyHandler: nil)
          }
      }

      // ✅ Send core temp only if valid (prevents 0.0 bug)
      if let coreTemp = HealthKitManager.shared.latestCoreTemp {
          DatabaseManager.shared.insertCoreTempPoint(CoreTempPoint(timestamp: timestamp, temp: coreTemp))
          DispatchQueue.main.async { self.coreTemp = coreTemp }

          if WCSession.default.isReachable {
              WCSession.default.sendMessage(["coreTemp": coreTemp], replyHandler: nil)
          }
      }
  }





    // MARK: - Receive Messages from Watch
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            if let type = message["type"] as? String {
                switch type {
                case "questionnaire":
                    self.handleQuestionnaire(message)
                case "workout_summary":
                    self.handleWorkoutSummary(message)
                default:
                    print("⚠️ Unknown message type: \(type)")
                }
            }
        }
    }

    // MARK: - Handle Questionnaire
    private func handleQuestionnaire(_ message: [String: Any]) {
        guard
            let workoutIdString = message["workoutId"] as? String,
            let timestamp = message["timestamp"] as? String,
            let exertion = message["exertion"] as? Int,
            let hydration = message["hydration"] as? Int,
            let thermal = message["thermal"] as? Int,
            let workoutId = UUID(uuidString: workoutIdString)
        else {
            print("🛑 Invalid questionnaire message")
            return
        }

        DatabaseManager.shared.insertQuestionnaireResponse(
            workoutId: workoutId,
            timestamp: timestamp,
            exertion: exertion,
            hydration: hydration,
            thermal: thermal
        )
    }

    // MARK: - Handle Workout Summary
    private func handleWorkoutSummary(_ message: [String: Any]) {
        guard
            let workoutIdString = message["workoutId"] as? String,
            let startTime = message["startTime"] as? String,
            let endTime = message["endTime"] as? String,
            let calories = message["calories"] as? Double,
            let steps = message["steps"] as? Int,
            let distance = message["distance"] as? Double,
            let coreTempMin = message["coreTempMin"] as? Double,
            let coreTempMax = message["coreTempMax"] as? Double,
            let coreTempAvg = message["coreTempAvg"] as? Double,
            let heartRateMin = message["heartRateMin"] as? Int,
            let heartRateMax = message["heartRateMax"] as? Int,
            let heartRateAvg = message["heartRateAvg"] as? Int,
            let workoutId = UUID(uuidString: workoutIdString)
        else {
            print("🛑 Invalid workout summary message")
            return
        }

        DatabaseManager.shared.insertWorkoutSummary(
            workoutId: workoutId,
            startTime: startTime,
            endTime: endTime,
            calories: calories,
            steps: steps,
            distance: distance,
            coreTempMin: coreTempMin,
            coreTempMax: coreTempMax,
            coreTempAvg: coreTempAvg,
            heartRateMin: heartRateMin,
            heartRateMax: heartRateMax,
            heartRateAvg: heartRateAvg
        )
    }

  // MARK: - Handle background delivery of workout summaries
  func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
      DispatchQueue.main.async {
          if let type = userInfo["type"] as? String, type == "workout_summary" {
              self.handleWorkoutSummary(userInfo)
          } else {
              print("📥 Received userInfo of unknown type: \(userInfo)")
          }
      }
  }

    // MARK: - Required WCSessionDelegate Methods
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

