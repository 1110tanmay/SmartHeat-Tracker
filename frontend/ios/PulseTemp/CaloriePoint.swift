import Foundation

struct CaloriePoint: Identifiable, Equatable {
    let id = UUID()
    let date: Date
    let calories: Double
}

