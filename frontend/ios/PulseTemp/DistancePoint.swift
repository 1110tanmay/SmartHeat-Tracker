import Foundation

struct DistancePoint: Identifiable, Equatable, Codable {
    let id = UUID()
    let timestamp: Date
    var distance: Double
}

