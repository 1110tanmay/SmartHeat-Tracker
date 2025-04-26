
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
}
