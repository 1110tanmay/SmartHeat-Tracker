import SwiftUI

@main
struct PulseTempApp: App {
    @StateObject private var healthKitManager = HealthKitManager.shared
    @State private var isAuthorized = false
    @State private var hasCheckedAuthorization = false
    @State private var didAcceptConsent = false

    init() {
        _ = WatchSessionManager.shared  // ✅ Ensure WatchConnectivity is active on launch
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCheckedAuthorization {
                    ProgressView("Checking HealthKit Access...")
                        .onAppear {
                            healthKitManager.requestAuthorization { success, _ in
                                DispatchQueue.main.async {
                                    self.isAuthorized = success
                                    self.hasCheckedAuthorization = true
                                }
                            }
                        }
                } else if !isAuthorized {
                    HealthAccessDeniedView()
                } else if !didAcceptConsent {
                    ConsentView {
                        self.didAcceptConsent = true
                    }
                } else {
                    ContentView()
                        .environmentObject(healthKitManager)
                }
            }
        }
    }
}

