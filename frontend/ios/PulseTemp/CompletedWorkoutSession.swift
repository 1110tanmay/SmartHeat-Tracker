import Foundation

struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let startTime: Date
    let endTime: Date
    var duration: TimeInterval {
        return endTime.timeIntervalSince(startTime)
    }

    var totalSteps: Int
    var totalDistance: Double
    var totalCalories: Double

    var averageHeartRate: Double?
    var maxHeartRate: Double?

    var averageCoreTemp: Double?
    var maxCoreTemp: Double?

    var heartRatePoints: [HeartRatePoint]
    var coreTempPoints: [CoreTempPoint]
    var stepPoints: [StepPoint]
    var caloriePoints: [CaloriePoint]
    var distancePoints: [DistancePoint]

}

// MARK: - Computed Properties for Min/Max/Avg Metrics

extension WorkoutSession {
    var coreTempMin: Double {
        coreTempPoints.map(\.temp).min() ?? 0
    }

    var coreTempAvg: Double {
        guard !coreTempPoints.isEmpty else { return 0 }
        return coreTempPoints.map(\.temp).reduce(0, +) / Double(coreTempPoints.count)
    }

    var coreTempMax: Double {
        coreTempPoints.map(\.temp).max() ?? 0
    }

    var heartRateMin: Int {
        Int(heartRatePoints.map(\.bpm).min() ?? 0)
    }

    var heartRateAvg: Int {
        guard !heartRatePoints.isEmpty else { return 0 }
        return Int(heartRatePoints.map(\.bpm).reduce(0, +) / Double(heartRatePoints.count))
    }

    var heartRateMax: Int {
        Int(heartRatePoints.map(\.bpm).max() ?? 0)
    }
}

