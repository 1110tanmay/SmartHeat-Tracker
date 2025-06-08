import SwiftUI

@main
struct PulseTemp_WatchApp: App {
    @StateObject private var workoutManager = WorkoutManager()

    var body: some Scene {
        WindowGroup {
            WorkoutSummaryView()
                .environmentObject(workoutManager)
                .onAppear {
                    // ✅ Request HealthKit permission when the app launches
                    workoutManager.requestAuthorization()
                }
        }
    }
}

