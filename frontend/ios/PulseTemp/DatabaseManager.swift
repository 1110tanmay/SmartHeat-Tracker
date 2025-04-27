import Foundation
import SQLite

typealias SQLiteExpression = SQLite.Expression

class DatabaseManager {
    static let shared = DatabaseManager()

    private let db: Connection

    // WorkoutSessions table and columns
    private let workoutSessions = Table("WorkoutSessions")
    private let id = SQLiteExpression<String>("id")
    private let startTime = SQLiteExpression<Date>("startTime")
    private let endTime = SQLiteExpression<Date>("endTime")
    private let totalSteps = SQLiteExpression<Int>("totalSteps")
    private let totalDistance = SQLiteExpression<Double>("totalDistance")
    private let totalCalories = SQLiteExpression<Double>("totalCalories")
    private let averageHeartRate = SQLiteExpression<Double?>("averageHeartRate")
    private let maxHeartRate = SQLiteExpression<Double?>("maxHeartRate")
    private let averageCoreTemp = SQLiteExpression<Double?>("averageCoreTemp")
    private let maxCoreTemp = SQLiteExpression<Double?>("maxCoreTemp")

    // UserProfile table and columns
    private let userProfile = Table("UserProfile")
    private let userId = SQLiteExpression<String>("id")
    private let name = SQLiteExpression<String>("name")
    private let age = SQLiteExpression<Int>("age")
    private let sex = SQLiteExpression<String>("sex")
    private let height = SQLiteExpression<Double>("height")
    private let weight = SQLiteExpression<Double>("weight")
    private let distanceUnit = SQLiteExpression<String>("distanceUnit")
    private let temperatureUnit = SQLiteExpression<String>("temperatureUnit")

    // CoreTempHistory table and columns
    private let coreTempHistory = Table("CoreTempHistory")
    private let coreTempTimestamp = SQLiteExpression<Date>("timestamp")
    private let coreTempValue = SQLiteExpression<Double>("temp")

    // New: HeartRateHistory table and columns
    private let heartRateHistory = Table("HeartRateHistory")
    private let heartRateTimestamp = SQLiteExpression<Date>("timestamp")
    private let heartRateBPM = SQLiteExpression<Double>("bpm")

    // New: StepsHistory table and columns
    private let stepsHistory = Table("StepsHistory")
    private let stepsTimestamp = SQLiteExpression<Date>("timestamp")
    private let stepsCount = SQLiteExpression<Int>("steps")

    // New: CaloriesHistory table and columns
    private let caloriesHistory = Table("CaloriesHistory")
    private let caloriesTimestamp = SQLiteExpression<Date>("timestamp")
    private let caloriesBurned = SQLiteExpression<Double>("calories")

    // New: DistanceHistory table and columns
    private let distanceHistory = Table("DistanceHistory")
    private let distanceTimestamp = SQLiteExpression<Date>("timestamp")
    private let distanceCovered = SQLiteExpression<Double>("distance")

    private init() {
        do {
            // 📌 Build the path inside Application Support Directory
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

            if !FileManager.default.fileExists(atPath: appSupportURL.path) {
                try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }

            let dbPath = appSupportURL.appendingPathComponent("workouts.sqlite").path
            db = try Connection(dbPath)

            try createWorkoutSessionTable()
            try createUserProfileTable()
            try createCoreTempHistoryTable()
            try createHeartRateHistoryTable()
            try createStepsHistoryTable()
            try createCaloriesHistoryTable()
            try createDistanceHistoryTable()
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

    private func createUserProfileTable() throws {
        try db.run(userProfile.create(ifNotExists: true) { table in
            table.column(userId, primaryKey: true)
            table.column(name)
            table.column(age)
            table.column(sex)
            table.column(height)
            table.column(weight)
            table.column(distanceUnit)
            table.column(temperatureUnit)
        })
    }

    private func createCoreTempHistoryTable() throws {
        try db.run(coreTempHistory.create(ifNotExists: true) { table in
            table.column(coreTempTimestamp, primaryKey: true)
            table.column(coreTempValue)
        })
    }

    private func createHeartRateHistoryTable() throws {
        try db.run(heartRateHistory.create(ifNotExists: true) { table in
            table.column(heartRateTimestamp, primaryKey: true)
            table.column(heartRateBPM)
        })
    }

    private func createStepsHistoryTable() throws {
        try db.run(stepsHistory.create(ifNotExists: true) { table in
            table.column(stepsTimestamp, primaryKey: true)
            table.column(stepsCount)
        })
    }

    private func createCaloriesHistoryTable() throws {
        try db.run(caloriesHistory.create(ifNotExists: true) { table in
            table.column(caloriesTimestamp, primaryKey: true)
            table.column(caloriesBurned)
        })
    }

    private func createDistanceHistoryTable() throws {
        try db.run(distanceHistory.create(ifNotExists: true) { table in
            table.column(distanceTimestamp, primaryKey: true)
            table.column(distanceCovered)
        })
    }

    // MARK: - Insert Workout
    func insertWorkout(_ session: WorkoutSession) {
        do {
            let insert = workoutSessions.insert(
                id <- session.id.uuidString,
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
            try db.run(insert)
        } catch {
            print("Failed to insert workout session: \(error)")
        }
    }

    // MARK: - Fetch Recent Workouts
    func fetchRecentWorkouts(limit: Int = 3) -> [WorkoutSession] {
        do {
            let rows = try db.prepare(workoutSessions.order(endTime.desc).limit(limit))
            return rows.compactMap { row in
                WorkoutSession(
                    id: UUID(uuidString: row[id]) ?? UUID(),
                    startTime: row[startTime],
                    endTime: row[endTime],
                    totalSteps: row[totalSteps],
                    totalDistance: row[totalDistance],
                    totalCalories: row[totalCalories],
                    averageHeartRate: row[averageHeartRate],
                    maxHeartRate: row[maxHeartRate],
                    averageCoreTemp: row[averageCoreTemp],
                    maxCoreTemp: row[maxCoreTemp],
                    heartRatePoints: [],
                    coreTempPoints: [],
                    stepPoints: []
                )
            }
        } catch {
            print("Failed to fetch recent workouts: \(error)")
            return []
        }
    }

    // MARK: - User Profile Functions
    func insertOrUpdateUserProfile(_ profile: UserProfile) {
        do {
            if try db.scalar(userProfile.filter(userId == profile.id).count) > 0 {
                let existing = userProfile.filter(userId == profile.id)
                try db.run(existing.update(
                    name <- profile.name,
                    age <- profile.age,
                    sex <- profile.sex,
                    height <- profile.height,
                    weight <- profile.weight,
                    distanceUnit <- profile.distanceUnit,
                    temperatureUnit <- profile.temperatureUnit
                ))
            } else {
                try db.run(userProfile.insert(
                    userId <- profile.id,
                    name <- profile.name,
                    age <- profile.age,
                    sex <- profile.sex,
                    height <- profile.height,
                    weight <- profile.weight,
                    distanceUnit <- profile.distanceUnit,
                    temperatureUnit <- profile.temperatureUnit
                ))
            }
        } catch {
            print("Failed to insert/update user profile: \(error)")
        }
    }

    func fetchUserProfile() -> UserProfile? {
        do {
            if let row = try db.pluck(userProfile) {
                return UserProfile(
                    id: row[userId],
                    name: row[name],
                    age: row[age],
                    sex: row[sex],
                    height: row[height],
                    weight: row[weight],
                    distanceUnit: row[distanceUnit],
                    temperatureUnit: row[temperatureUnit]
                )
            }
        } catch {
            print("Failed to fetch user profile: \(error)")
        }
        return nil
    }

    // MARK: - Core Temp Functions
    func insertCoreTempPoint(_ point: CoreTempPoint) {
        do {
            let insert = coreTempHistory.insert(
                coreTempTimestamp <- point.timestamp,
                coreTempValue <- point.temp
            )
            try db.run(insert)
        } catch {
            print("Failed to insert CoreTempPoint: \(error)")
        }
    }

    func fetchAllCoreTempPoints() -> [CoreTempPoint] {
        do {
            let rows = try db.prepare(coreTempHistory.order(coreTempTimestamp.asc))
            return rows.map { row in
                CoreTempPoint(timestamp: row[coreTempTimestamp], temp: row[coreTempValue])
            }
        } catch {
            print("Failed to fetch CoreTempPoints: \(error)")
            return []
        }
    }

    // MARK: - New Insert Functions for HeartRate, Steps, Calories, Distance
    func insertHeartRatePoint(_ point: HeartRatePoint) {
        do {
            let insert = heartRateHistory.insert(
                heartRateTimestamp <- point.timestamp,
                heartRateBPM <- point.bpm
            )
            try db.run(insert)
        } catch {
            print("Failed to insert HeartRatePoint: \(error)")
        }
    }

    func insertStepPoint(_ point: StepPoint) {
        do {
            let insert = stepsHistory.insert(
                stepsTimestamp <- point.timestamp,
                stepsCount <- point.steps
            )
            try db.run(insert)
        } catch {
            print("Failed to insert StepPoint: \(error)")
        }
    }

    func insertCaloriePoint(_ point: CaloriePoint) {
        do {
            let insert = caloriesHistory.insert(
                caloriesTimestamp <- point.timestamp,
                caloriesBurned <- point.calories
            )
            try db.run(insert)
        } catch {
            print("Failed to insert CaloriePoint: \(error)")
        }
    }

    func insertDistancePoint(_ point: DistancePoint) {
        do {
            let insert = distanceHistory.insert(
                distanceTimestamp <- point.timestamp,
                distanceCovered <- point.distance
            )
            try db.run(insert)
        } catch {
            print("Failed to insert DistancePoint: \(error)")
        }
    }

    // MARK: - New Fetch Functions for HeartRate, Steps, Calories, Distance
    func fetchAllHeartRatePoints() -> [HeartRatePoint] {
        do {
            let rows = try db.prepare(heartRateHistory.order(heartRateTimestamp.asc))
            return rows.map { row in
                HeartRatePoint(timestamp: row[heartRateTimestamp], bpm: row[heartRateBPM])
            }
        } catch {
            print("Failed to fetch HeartRatePoints: \(error)")
            return []
        }
    }

    func fetchAllStepPoints() -> [StepPoint] {
        do {
            let rows = try db.prepare(stepsHistory.order(stepsTimestamp.asc))
            return rows.map { row in
                StepPoint(timestamp: row[stepsTimestamp], steps: row[stepsCount])
            }
        } catch {
            print("Failed to fetch StepPoints: \(error)")
            return []
        }
    }

    func fetchAllCaloriePoints() -> [CaloriePoint] {
        do {
            let rows = try db.prepare(caloriesHistory.order(caloriesTimestamp.asc))
            return rows.map { row in
                CaloriePoint(timestamp: row[caloriesTimestamp], calories: row[caloriesBurned])
            }
        } catch {
            print("Failed to fetch CaloriePoints: \(error)")
            return []
        }
    }

    func fetchAllDistancePoints() -> [DistancePoint] {
        do {
            let rows = try db.prepare(distanceHistory.order(distanceTimestamp.asc))
            return rows.map { row in
                DistancePoint(timestamp: row[distanceTimestamp], distance: row[distanceCovered])
            }
        } catch {
            print("Failed to fetch DistancePoints: \(error)")
            return []
        }
    }
  
}

