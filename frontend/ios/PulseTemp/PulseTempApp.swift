import SwiftUI

@main
struct PulseTempApp: App {
    @StateObject private var healthKitManager = HealthKitManager.shared

    init() {
        _ = WatchSessionManager.shared  // ✅ Ensure WatchConnectivity is active on launch
      HealthKitManager.shared.startLiveSync()  // ✅ Start live heart rate & temp sync to Watch
    }

    var body: some Scene {
        WindowGroup {
            OnboardingFlowView()
                .environmentObject(healthKitManager)
        }
    }
}

