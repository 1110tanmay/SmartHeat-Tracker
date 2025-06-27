import SwiftUI

@main
struct PulseTempApp: App {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @StateObject private var connectivityManager = WatchConnectivityManager.shared

    init() {
        // ✅ Ensures WCSession is activated
        _ = WatchConnectivityManager.shared

        // ✅ Start live data collection
        HealthKitManager.shared.startLiveSync()

        // ✅ Start sending data to watch
        WatchConnectivityManager.shared.startSendingSensorData()
    }

    var body: some Scene {
        WindowGroup {
            OnboardingFlowView()
                .environmentObject(healthKitManager)
                .environmentObject(connectivityManager)
        }
    }
}

