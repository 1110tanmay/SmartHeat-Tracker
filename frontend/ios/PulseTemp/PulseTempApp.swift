
import SwiftUI

@main
struct PulseTempApp: App {
    private var healthKitManager = HealthKitManager.shared
    private var connectivityManager = WatchConnectivityManager.shared

    var body: some Scene {
        WindowGroup {
            OnboardingFlowView()
                .environmentObject(healthKitManager)
                .environmentObject(connectivityManager)
                .onAppear {
                    healthKitManager.fetchAllMetricsForInitialSync()
                }
        }
    }
}
