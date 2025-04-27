import Foundation

struct CaloriePoint: Identifiable, Codable, Equatable {
    let id = UUID()
    let timestamp: Date
    var calories: Double
}

