// In LiveWorkoutData.swift

import Foundation

// This struct will be our new, robust "envelope" for live data.
// Because it's a single object, SwiftUI will reliably detect
// when it changes, forcing the UI to update.
struct LiveWorkoutData: Codable {
    var heartRate: Double
    var coreTemp: Double
}
