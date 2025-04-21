import Foundation

struct CaloriePoint: Identifiable, Equatable {
    let id = UUID()
    let timestamp: String
    let calories: Double
}
