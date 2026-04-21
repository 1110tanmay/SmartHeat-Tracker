import Foundation
import SQLite

typealias SQLiteExpression = SQLite.Expression

class DatabaseManager {
    static let shared = DatabaseManager()

    private let db: Connection

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
    private let questionnaireResponses = Table("QuestionnaireResponses")
    private let qWorkoutId = SQLiteExpression<String>("workoutId")
    private let qTimestamp = SQLiteExpression<String>("timestamp")
    private let qExertion = SQLiteExpression<Int>("exertion")
    private let qHydration = SQLiteExpression<Int>("hydration")
    private let qThermal = SQLiteExpression<Int>("thermal")

    private let userProfile = Table("UserProfile")
    private let userId = SQLiteExpression<String>("id")
    private let name = SQLiteExpression<String>("name")
    private let dob = SQLiteExpression<Date>("dob")
    private let sex = SQLiteExpression<String>("sex")
    private let ethnicity = SQLiteExpression<String>("ethnicity")
    private let profession = SQLiteExpression<String>("profession")
    private let height = SQLiteExpression<Double>("height")
    private let weight = SQLiteExpression<Double>("weight")
    private let distanceUnit = SQLiteExpression<String>("distanceUnit")
    private let temperatureUnit = SQLiteExpression<String>("temperatureUnit")
    private let activityLevel = SQLiteExpression<Int>("activityLevel")

    private let coreTempHistory = Table("CoreTempHistory")
    private let coreTempTimestamp = SQLiteExpression<Date>("timestamp")
    private let coreTempValue = SQLiteExpression<Double>("temp")
    private let coreTempWorkoutId = SQLiteExpression<String>("workoutId")

    private let heartRateHistory = Table("HeartRateHistory")
    private let heartRateTimestamp = SQLiteExpression<Date>("timestamp")
    private let heartRateBPM = SQLiteExpression<Double>("bpm")
    private let heartRateWorkoutId = SQLiteExpression<String>("workoutId")

    private let stepsHistory = Table("StepsHistory")
    private let stepsTimestamp = SQLiteExpression<Date>("timestamp")
    private let stepsCount = SQLiteExpression<Int>("steps")

    private let caloriesHistory = Table("CaloriesHistory")
    private let caloriesTimestamp = SQLiteExpression<Date>("timestamp")
    private let caloriesBurned = SQLiteExpression<Double>("calories")

    private let distanceHistory = Table("DistanceHistory")
    private let distanceTimestamp = SQLiteExpression<Date>("timestamp")
    private let distanceCovered = SQLiteExpression<Double>("distance")

    private init() {
        do {
            let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
            if !FileManager.default.fileExists(atPath: appSupportURL.path) {
                try FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)
            }

            let dbPath = appSupportURL.appendingPathComponent("workouts.sqlite").path
            print("📁 DB Path: \(dbPath)")
            db = try Connection(dbPath)

            try createWorkoutSessionTable()
            try createQuestionnaireResponsesTable() // ✅
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
  
  private let iso8601Formatter: ISO8601DateFormatter = {
      let f = ISO8601DateFormatter()
      f.formatOptions = [.withInternetDateTime]
      return f
  }()


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

    private func createQuestionnaireResponsesTable() throws {
        try db.run(questionnaireResponses.create(ifNotExists: true) { table in
            table.column(qWorkoutId)
            table.column(qTimestamp)
            table.column(qExertion)
            table.column(qHydration)
            table.column(qThermal)
        })
    }

    private func createUserProfileTable() throws {
        try db.run(userProfile.create(ifNotExists: true) { table in
            table.column(userId, primaryKey: true)
            table.column(name)
            table.column(dob)
            table.column(sex)
            table.column(ethnicity)
            table.column(profession)
            table.column(height)
            table.column(weight)
            table.column(distanceUnit)
            table.column(temperatureUnit)
            table.column(activityLevel)
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
  func insertOrUpdateUserProfile(_ profile: UserProfile) {
      do {
          let existing = userProfile.filter(userId == profile.id)
          if try db.scalar(existing.count) > 0 {
              try db.run(existing.update(
                  name <- profile.name,
                  dob <- profile.dob,
                  sex <- profile.sex,
                  ethnicity <- profile.ethnicity,
                  profession <- profile.profession,
                  height <- profile.height,
                  weight <- profile.weight,
                  distanceUnit <- profile.distanceUnit,
                  temperatureUnit <- profile.temperatureUnit,
                  activityLevel <- profile.activityLevel
              ))
          } else {
              try db.run(userProfile.insert(
                  userId <- profile.id,
                  name <- profile.name,
                  dob <- profile.dob,
                  sex <- profile.sex,
                  ethnicity <- profile.ethnicity,
                  profession <- profile.profession,
                  height <- profile.height,
                  weight <- profile.weight,
                  distanceUnit <- profile.distanceUnit,
                  temperatureUnit <- profile.temperatureUnit,
                  activityLevel <- profile.activityLevel
              ))
          }
      } catch {
          print("❌ Failed to insert/update user profile: \(error)")
      }
  }
  func fetchUserProfile() -> UserProfile? {
      do {
          if let row = try db.pluck(userProfile) {
              return UserProfile(
                  id: row[userId],
                  name: row[name],
                  dob: row[dob],
                  sex: row[sex],
                  ethnicity: row[ethnicity],
                  profession: row[profession],
                  height: row[height],
                  weight: row[weight],
                  distanceUnit: row[distanceUnit],
                  temperatureUnit: row[temperatureUnit],
                  activityLevel: row[activityLevel]
              )
          }
      } catch {
          print("❌ Failed to fetch user profile: \(error)")
      }
      return nil
  }

    // MARK: - Fetch Activity Level ✅
    func fetchActivityLevel() -> Int? {
        do {
            if let row = try db.pluck(userProfile) {
                return row[activityLevel]
            }
        } catch {
            print("Failed to fetch activity level: \(error)")
        }
        return nil
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
  
  func insertWorkoutSummary(
      workoutId: UUID,
      startTime: String,
      endTime: String,
      calories: Double,
      steps: Int,
      distance: Double,
      coreTempMin: Double, // ← will be ignored
      coreTempMax: Double, // ← will be ignored
      coreTempAvg: Double, // ← will be ignored
      heartRateMin: Int,   // ← will be ignored
      heartRateMax: Int,   // ← will be ignored
      heartRateAvg: Int    // ← will be ignored
  ) {
      let formatter = ISO8601DateFormatter()
      guard let start = formatter.date(from: startTime),
            let end = formatter.date(from: endTime) else {
          print("🛑 Failed to parse date strings in insertWorkoutSummary")
          return
      }

      // Fetch data from time-series tables between start and end
      let coreTemps = fetchAllCoreTempPoints().filter {
          $0.timestamp >= start && $0.timestamp <= end
      }.map { $0.temp }

      let heartRates = fetchAllHeartRatePoints().filter {
          $0.timestamp >= start && $0.timestamp <= end
      }.map { $0.bpm }

      // Compute stats on the phone side (source of truth)
      let ctMin = coreTemps.min() ?? 0
      let ctMax = coreTemps.max() ?? 0
      let ctAvg = coreTemps.isEmpty ? 0 : coreTemps.reduce(0, +) / Double(coreTemps.count)

      let hrMin = heartRates.min() ?? 0
      let hrMax = heartRates.max() ?? 0
      let hrAvg = heartRates.isEmpty ? 0 : heartRates.reduce(0, +) / Double(heartRates.count)

      do {
          let insert = workoutSessions.insert(
              id <- workoutId.uuidString,
              self.startTime <- start,
              self.endTime <- end,
              totalSteps <- steps,
              totalDistance <- distance,
              totalCalories <- calories,
              averageHeartRate <- hrAvg,
              maxHeartRate <- hrMax,
              averageCoreTemp <- ctAvg,
              maxCoreTemp <- ctMax
          )
          try db.run(insert)
          print("✅ Workout summary inserted (calculated from time-series data) for ID \(workoutId)")
          DispatchQueue.main.async {
              NotificationCenter.default.post(name: NSNotification.Name("WorkoutDataUpdated"), object: nil)
          }
      } catch {
          print("🛑 Failed to insert workout summary: \(error)")
      }
  }


    // MARK: - Insert Questionnaire Response ✅
    func insertQuestionnaireResponse(workoutId: UUID, timestamp: String, exertion: Int, hydration: Int, thermal: Int) {
        do {
            try db.run(questionnaireResponses.insert(
                qWorkoutId <- workoutId.uuidString,
                qTimestamp <- timestamp,
                qExertion <- exertion,
                qHydration <- hydration,
                qThermal <- thermal
            ))
            print("✅ Questionnaire response saved to DB for workout \(workoutId)")
        } catch {
            print("🛑 Failed to insert questionnaire response: \(error)")
        }
    }

    // MARK: - Fetch Recent Workouts
  func fetchRecentWorkouts(limit: Int = 3) -> [WorkoutSession] {
      do {
          let rows = try db.prepare(workoutSessions.order(endTime.desc).limit(limit))
          return rows.compactMap { row in
              let sessionStart = row[startTime]
              let sessionEnd = row[endTime]

              // Filter heart rate points within workout time range
              let hrPoints = fetchAllHeartRatePoints().filter {
                  $0.timestamp >= sessionStart && $0.timestamp <= sessionEnd
              }

              // Filter core temp points within workout time range
              let tempPoints = fetchAllCoreTempPoints().filter {
                  $0.timestamp >= sessionStart && $0.timestamp <= sessionEnd
              }

            let stepPoints = fetchAllStepPoints().filter {
                $0.timestamp >= sessionStart && $0.timestamp <= sessionEnd
            }

            let caloriePoints = fetchAllCaloriePoints().filter {
                $0.timestamp >= sessionStart && $0.timestamp <= sessionEnd
            }

            let distancePoints = fetchAllDistancePoints().filter {
                $0.timestamp >= sessionStart && $0.timestamp <= sessionEnd
            }

            return WorkoutSession(
                id: UUID(uuidString: row[id]) ?? UUID(),
                startTime: sessionStart,
                endTime: sessionEnd,
                totalSteps: row[totalSteps],
                totalDistance: row[totalDistance],
                totalCalories: row[totalCalories],
                averageHeartRate: row[averageHeartRate],
                maxHeartRate: row[maxHeartRate],
                averageCoreTemp: row[averageCoreTemp],
                maxCoreTemp: row[maxCoreTemp],
                heartRatePoints: hrPoints,
                coreTempPoints: tempPoints,
                stepPoints: stepPoints,
                caloriePoints: caloriePoints,
                distancePoints: distancePoints
            )

          }
      } catch {
          print("Failed to fetch recent workouts: \(error)")
          return []
      }
  }


    // MARK: - Health Data Insert Methods
    func insertCoreTempPoint(_ point: CoreTempPoint) {
        do {
            try db.run(coreTempHistory.insert(coreTempTimestamp <- point.timestamp, coreTempValue <- point.temp))
        } catch {
            // Backward-compatible fallback for older on-device schema versions
            // that enforce NOT NULL on CoreTempHistory.workoutId.
            let message = String(describing: error)
            if message.contains("CoreTempHistory.workoutId") && message.contains("NOT NULL constraint failed") {
                do {
                    try db.run(coreTempHistory.insert(
                        coreTempTimestamp <- point.timestamp,
                        coreTempValue <- point.temp,
                        coreTempWorkoutId <- "legacy"
                    ))
                    return
                } catch {
                    print("Failed to insert CoreTempPoint (legacy fallback): \(error)")
                }
            } else {
                print("Failed to insert CoreTempPoint: \(error)")
            }
        }
    }

    func insertHeartRatePoint(_ point: HeartRatePoint) {
        do {
            try db.run(heartRateHistory.insert(heartRateTimestamp <- point.timestamp, heartRateBPM <- point.bpm))
        } catch {
            // Backward-compatible fallback for older on-device schema versions
            // that enforce NOT NULL on HeartRateHistory.workoutId.
            let message = String(describing: error)
            if message.contains("HeartRateHistory.workoutId") && message.contains("NOT NULL constraint failed") {
                do {
                    try db.run(heartRateHistory.insert(
                        heartRateTimestamp <- point.timestamp,
                        heartRateBPM <- point.bpm,
                        heartRateWorkoutId <- "legacy"
                    ))
                    return
                } catch {
                    print("Failed to insert HeartRatePoint (legacy fallback): \(error)")
                }
            } else {
                print("Failed to insert HeartRatePoint: \(error)")
            }
        }
    }

    func insertStepPoint(_ point: StepPoint) {
        do {
            try db.run(stepsHistory.insert(stepsTimestamp <- point.timestamp, stepsCount <- point.steps))
        } catch {
            print("Failed to insert StepPoint: \(error)")
        }
    }

    func insertCaloriePoint(_ point: CaloriePoint) {
        do {
            try db.run(caloriesHistory.insert(caloriesTimestamp <- point.timestamp, caloriesBurned <- point.calories))
        } catch {
            print("Failed to insert CaloriePoint: \(error)")
        }
    }

    func insertDistancePoint(_ point: DistancePoint) {
        do {
            try db.run(distanceHistory.insert(distanceTimestamp <- point.timestamp, distanceCovered <- point.distance))
        } catch {
            print("Failed to insert DistancePoint: \(error)")
        }
    }

    // MARK: - Health Data Fetch Methods
    func fetchAllCoreTempPoints() -> [CoreTempPoint] {
        do {
            return try db.prepare(coreTempHistory.order(coreTempTimestamp.asc)).map {
                CoreTempPoint(timestamp: $0[coreTempTimestamp], temp: $0[coreTempValue])
            }
        } catch {
            print("Failed to fetch CoreTempPoints: \(error)")
            return []
        }
    }

    func fetchAllHeartRatePoints() -> [HeartRatePoint] {
        do {
            return try db.prepare(heartRateHistory.order(heartRateTimestamp.asc)).map {
                HeartRatePoint(timestamp: $0[heartRateTimestamp], bpm: $0[heartRateBPM])
            }
        } catch {
            print("Failed to fetch HeartRatePoints: \(error)")
            return []
        }
    }

    func fetchAllStepPoints() -> [StepPoint] {
        do {
            return try db.prepare(stepsHistory.order(stepsTimestamp.asc)).map {
                StepPoint(timestamp: $0[stepsTimestamp], steps: $0[stepsCount])
            }
        } catch {
            print("Failed to fetch StepPoints: \(error)")
            return []
        }
    }

    func fetchAllCaloriePoints() -> [CaloriePoint] {
        do {
            return try db.prepare(caloriesHistory.order(caloriesTimestamp.asc)).map {
                CaloriePoint(timestamp: $0[caloriesTimestamp], calories: $0[caloriesBurned])
            }
        } catch {
            print("Failed to fetch CaloriePoints: \(error)")
            return []
        }
    }

    func fetchAllDistancePoints() -> [DistancePoint] {
        do {
            return try db.prepare(distanceHistory.order(distanceTimestamp.asc)).map {
                DistancePoint(timestamp: $0[distanceTimestamp], distance: $0[distanceCovered])
            }
        } catch {
            print("Failed to fetch DistancePoints: \(error)")
            return []
        }
    }
  
  // MARK: - Fetch Calorie Point at Timestamp
  func fetchClosestCaloriePoint(to timestamp: Date) -> CaloriePoint? {
      let windowStart = timestamp.addingTimeInterval(-3)
      let windowEnd = timestamp.addingTimeInterval(3)

      do {
          let query = caloriesHistory
              .filter(caloriesTimestamp >= windowStart && caloriesTimestamp <= windowEnd)
          let points = try db.prepare(query).map {
              CaloriePoint(timestamp: $0[caloriesTimestamp], calories: $0[caloriesBurned])
          }

          return points.min(by: { abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp)) })
      } catch {
          print("❌ Failed to fetch closest CaloriePoint near \(timestamp): \(error)")
          return nil
      }
  }



  // MARK: - Fetch Distance Point at Timestamp
  func fetchClosestDistancePoint(to timestamp: Date) -> DistancePoint? {
      let windowStart = timestamp.addingTimeInterval(-3)
      let windowEnd = timestamp.addingTimeInterval(3)

      do {
          let query = distanceHistory
              .filter(distanceTimestamp >= windowStart && distanceTimestamp <= windowEnd)
          let points = try db.prepare(query).map {
              DistancePoint(timestamp: $0[distanceTimestamp], distance: $0[distanceCovered])
          }

          return points.min(by: { abs($0.timestamp.timeIntervalSince(timestamp)) < abs($1.timestamp.timeIntervalSince(timestamp)) })
      } catch {
          print("❌ Failed to fetch closest DistancePoint near \(timestamp): \(error)")
          return nil
      }
  }



  func fetchQuestionnaireResponses(for workoutId: UUID) -> [(timestamp: String, exertion: Int, hydration: Int, thermal: Int)] {
      do {
          let query = questionnaireResponses.filter(qWorkoutId == workoutId.uuidString)
          let results = try db.prepare(query)
          return results.map { row in
              (
                  timestamp: row[qTimestamp],
                  exertion: row[qExertion],
                  hydration: row[qHydration],
                  thermal: row[qThermal]
              )
          }
      } catch {
          print("🛑 Failed to fetch questionnaire responses for workout \(workoutId): \(error)")
          return []
      }
  }

}

