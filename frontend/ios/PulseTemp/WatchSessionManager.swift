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
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("📩 Received message from Watch: \(message)")

        guard message["type"] as? String == "questionnaire" else { return }

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

