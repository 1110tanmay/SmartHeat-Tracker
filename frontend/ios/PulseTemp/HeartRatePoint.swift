import Foundation

struct HeartRatePoint: Identifiable {
    let id = UUID()
    let timestamp: Date
    let bpm: Int
}

