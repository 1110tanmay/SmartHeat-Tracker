import Foundation
import SQLite

class DatabaseManager {
    static let shared = DatabaseManager()

    private let db: Connection

    // Table and columns
    private let workoutSessions = Table("WorkoutSessions")

    private let id = Expression<String>("id")
    private let startTime = Expression<Date>("startTime")
    private let endTime = Expression<Date>("endTime")
    private let totalSteps = Expression<Int>("totalSteps")
    private let totalDistance = Expression<Double>("totalDistance")
    private let totalCalories = Expression<Double>("totalCalories")
    private let averageHeartRate = Expression<Double?>("averageHeartRate")
    private let maxHeartRate = Expression<Double?>("maxHeartRate")
    private let averageCoreTemp = Expression<Double?>("averageCoreTemp")
    private let maxCoreTemp = Expression<Double?>("maxCoreTemp")

    private init() {
        let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
            .appendingPathComponent("workouts.sqlite").path

        do {
            db = try Connection(path)
            try createWorkoutSessionTable()
        } catch {
            fatalError("Database connection failed: \(error)")
        }
    }

    private func createWorkoutSessionTable() throws {
        try db.run(workoutSessions.create(ifNotExists: true) { table in
            table.column(id, primaryKey: true)
            table.column(startTime)
            table.column(endTime)
            table.column(totalSteps)
            table.column(totalDistance)
            table.column(totalCalories)
            table.column(averageHeartRate)
            table.column(maxHeartRate)
            table.column(averageCoreTemp)
            table.column(maxCoreTemp)
        })
    }

    func insertWorkout(_ session: WorkoutSession) {
        let insert = workoutSessions.insert(
            id <- session.id,
            startTime <- session.startTime,
            endTime <- session.endTime,
            totalSteps <- session.totalSteps,
            totalDistance <- session.totalDistance,
            totalCalories <- session.totalCalories,
            averageHeartRate <- session.averageHeartRate,
            maxHeartRate <- session.maxHeartRate,
            averageCoreTemp <- session.averageCoreTemp,
            maxCoreTemp <- session.maxCoreTemp
        )

        do {
            try db.run(insert)
        } catch {
            print("Insert failed: \(error)")
        }
    }
}

