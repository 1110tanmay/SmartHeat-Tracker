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

  private init() {
      do {
          // 📌 Build the path inside Application Support Directory
          let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!

          // 📌 Ensure Application Support directory exists
          if !FileManager.default.fileExists(atPath: appSupportURL.path) {
              try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
          }

          let dbPath = appSupportURL.appendingPathComponent("workouts.sqlite").path

          db = try Connection(dbPath)

          try createWorkoutSessionTable()
          try createUserProfileTable()
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
                // Update existing profile
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
                // Insert new profile
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
}

