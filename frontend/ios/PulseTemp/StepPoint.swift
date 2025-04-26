import Foundation

struct StepPoint: Identifiable, Equatable, Codable {
    let id = UUID()
    let timestamp: Date    // ✅ Correct type for chart x-axis
    var steps: Int
}

