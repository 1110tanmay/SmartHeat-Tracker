import SwiftUI

@main
struct PulseTempApp: App {
    @StateObject private var healthKitManager = HealthKitManager.shared

    init() {
        _ = WatchSessionManager.shared  // ✅ Ensure session is activated on launch
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(healthKitManager)
        }
    }
}

