import Foundation
import WatchConnectivity

class WatchSessionManager: NSObject, WCSessionDelegate {
    static let shared = WatchSessionManager()

    private override init() {
        super.init()
        activateSession()
    }

    private func activateSession() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
            print("📲 iPhone WCSession activated")
        }
    }

    // MARK: - Incoming Messages from Watch
  // MARK: - Incoming Messages from Watch
  func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
      print("📩 Received message from Watch: \(message)")

      if message["type"] as? String == "questionnaire" {
          if let exertion = message["exertion"] as? Int,
             let hydration = message["hydration"] as? Int,
             let thermal = message["thermal"] as? Int,
             let timestamp = message["timestamp"] as? String,
             let workoutIdString = message["workoutId"] as? String,
             let workoutId = UUID(uuidString: workoutIdString) {

              // ✅ Save to SQLite with workout ID
              DatabaseManager.shared.insertQuestionnaireResponse(
                  workoutId: workoutId,
                  timestamp: timestamp,
                  exertion: exertion,
                  hydration: hydration,
                  thermal: thermal
              )
          } else {
              print("🛑 Invalid or missing data in questionnaire message")
          }

      } else if message["type"] as? String == "workout_summary" {
          if let workoutIdString = message["workoutId"] as? String,
             let workoutId = UUID(uuidString: workoutIdString),
             let start = message["startTime"] as? String,
             let end = message["endTime"] as? String,
             let calories = message["calories"] as? Double,
             let steps = message["steps"] as? Int,
             let distance = message["distance"] as? Double,
             let coreMin = message["coreTempMin"] as? Double,
             let coreMax = message["coreTempMax"] as? Double,
             let coreAvg = message["coreTempAvg"] as? Double,
             let hrMin = message["heartRateMin"] as? Int,
             let hrMax = message["heartRateMax"] as? Int,
             let hrAvg = message["heartRateAvg"] as? Int {

              // ✅ Save summary workout data to SQLite
              DatabaseManager.shared.insertWorkoutSummary(
                  workoutId: workoutId,
                  startTime: start,
                  endTime: end,
                  calories: calories,
                  steps: steps,
                  distance: distance,
                  coreTempMin: coreMin,
                  coreTempMax: coreMax,
                  coreTempAvg: coreAvg,
                  heartRateMin: hrMin,
                  heartRateMax: hrMax,
                  heartRateAvg: hrAvg
              )
          } else {
              print("🛑 Invalid or missing data in workout_summary message")
          }
      }
  }

    // MARK: - Required WCSessionDelegate Methods
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let error = error {
            print("🛑 WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ iPhone WCSession activation complete with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("ℹ️ WCSession became inactive")
    }

    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
        print("🔁 WCSession deactivated and reactivated")
    }
}

