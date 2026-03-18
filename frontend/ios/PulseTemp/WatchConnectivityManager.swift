import Foundation
import WatchConnectivity

  class WatchConnectivityManager: NSObject, WCSessionDelegate, ObservableObject {
  static let shared = WatchConnectivityManager()
  private let ecTempCalculator = ECTempCalculator()
    
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
    func updateWatchApplicationContext(hr: Double, temp: Double) {
        guard WCSession.default.activationState == .activated else {
            print("🛑 IPHONE: WCSession is not activated for context update.")
            return
        }

        let context: [String: Any] = [
            "heartRate": hr,
            "coreTemp": temp
        ]

        do {
            try WCSession.default.updateApplicationContext(context)
            print("✅ IPHONE: Sent on-demand context to watch - HR: \(hr), Temp: \(temp)")
        } catch {
            print("🛑 IPHONE: Error sending context: \(error.localizedDescription)")
        }
    }

    func sendLiveWorkoutData(hr: Double, temp: Double) {
           guard WCSession.default.isReachable else {
               return
           }

           let message: [String: Any] = [
               "type": "live_workout_data",
               "heartRate": hr,
               "coreTemp": temp
           ]

           WCSession.default.sendMessage(message, replyHandler: nil) { error in
               print("🛑 IPHONE: Failed to send live workout data: \(error.localizedDescription)")
           }
       }
    
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("📱 WCSession received a context, but it is not being used for the live HR loop: \(applicationContext)")
    }
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
      DispatchQueue.main.async {
          // Check for the "type" key to know what to do
          if let type = message["type"] as? String, type == "live_workout_data" {
              // This is our new case for live data
              self.handleLiveWorkoutData(message)

          } else if let type = message["type"] as? String, type == "questionnaire" {
              // This is your existing case, it stays the same
              self.handleQuestionnaire(message)
              
          } else {
              print("⚠️ Received message of unknown type: \(message)")
          }
      }
    }
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

    private func handleLiveWorkoutData(_ message: [String: Any]) {
        guard
            let hr = message["heartRate"] as? Double,
            let temp = message["coreTemp"] as? Double
        else {
            print("🛑 WATCH/IPHONE: Invalid live workout data message format")
            return
        }

        // Update the @Published properties. This will automatically update any SwiftUI views.
        self.heartRate = hr
        self.coreTemp = temp
        print("✅ Live data updated - HR: \(hr), Temp: \(temp)")
    }
  
    func session(_ session: WCSession, didReceiveUserInfo userInfo: [String : Any] = [:]) {
      DispatchQueue.main.async {
        print("⚠️ IPHONE: Received UserInfo via legacy method. This is no longer used for workout summaries. Data: \(userInfo)")
      }
    }
    
    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        if let error = error {
            print("🛑 IPHONE: File transfer failed with error: \(error.localizedDescription)")
            return
        }

        let fileURL = fileTransfer.file.fileURL
        print("📥 IPHONE: Received workout summary file at URL: \(fileURL.path)")

        Task(priority: .background) {
            do {
                let data = try Data(contentsOf: fileURL)
                let summary = try JSONDecoder().decode(WorkoutSummary.self, from: data)

                print("✅ IPHONE: Successfully decoded summary for workout ID: \(summary.id)")

              // Format dates as strings for insertion
              let isoFormatter = ISO8601DateFormatter()

              DatabaseManager.shared.insertWorkoutSummary(
                             workoutId: summary.id,
                             startTime: isoFormatter.string(from: summary.startTime),
                             endTime: isoFormatter.string(from: summary.endTime),
                             calories: summary.calories,
                             steps: summary.steps,
                             distance: summary.distance,
                             coreTempMin: summary.coreTempMin,
                             coreTempMax: summary.coreTempMax,
                             coreTempAvg: summary.coreTempAverage,
                             heartRateMin: summary.heartRateMin,
                             heartRateMax: summary.heartRateMax,
                             heartRateAvg: Int(summary.heartRateAverage)
                         )
                
                try? FileManager.default.removeItem(at: fileURL)

            } catch {
                print("🛑 IPHONE: Error processing received file: \(error.localizedDescription)")
            }
        }
    }
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        WCSession.default.activate()
    }
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {}
}

