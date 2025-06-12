import SwiftUI

@main
struct PulseTempApp: App {
    @StateObject private var healthKitManager = HealthKitManager.shared

    init() {
        _ = WatchSessionManager.shared  // ✅ Ensure WatchConnectivity is active on launch
    }

    var body: some Scene {
        WindowGroup {
            OnboardingFlowView()
                .environmentObject(healthKitManager)
        }
    }
}

