import Foundation

struct DistancePoint: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    var distance: Double
}

