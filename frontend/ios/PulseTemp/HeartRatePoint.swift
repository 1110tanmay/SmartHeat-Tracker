import Foundation

struct HeartRatePoint: Identifiable, Codable {
    var id = UUID()
    var timestamp: Date
    var bpm: Double // ➡️ Double, not Int
}

