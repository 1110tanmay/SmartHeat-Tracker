import Foundation

class ResearchExportManager {
    static let shared = ResearchExportManager()

    func exportToCSV(userProfile: UserProfile, workouts: [WorkoutSession]) -> URL? {
        return ResearchExportManager.generateResearchExportFileCSV()
    }

    static func generateResearchExportFileCSV() -> URL? {
        var csv = ""

        // MARK: Sheet 1 - User Info
        if let user = DatabaseManager.shared.fetchUserProfile() {
            print("✅ Profile loaded: \(user)")
            csv += "De-Identified User Info\n"
            csv += "ID,Activity Level,Age,Gender,Ethnicity,Profession\n"
            let id = UUID().uuidString.prefix(8)
            let age = calculateAge(from: user.dob)
            csv += "\(id),\(user.activityLevel),\(age),\(user.sex),\(user.ethnicity),\(user.profession)\n\n"
        }

        // MARK: Sheets 2–4 - Workouts
        let workouts = DatabaseManager.shared.fetchRecentWorkouts(limit: 3)
        print("✅ Workouts loaded: \(workouts.count) entries")

        for (index, workout) in workouts.enumerated() {
            csv += "Workout \(index + 1)\n"
            csv += "Timestamp,Calories,Distance,Steps,Heart Rate,Temperature\n"

            let rows = max(workout.stepPoints.count, workout.heartRatePoints.count, workout.coreTempPoints.count)

            for i in 0..<rows {
                let timestamp = workout.stepPoints[safe: i]?.timestamp ??
                                workout.heartRatePoints[safe: i]?.timestamp ??
                                workout.coreTempPoints[safe: i]?.timestamp ?? Date()

              let caloriePoint = DatabaseManager.shared.fetchClosestCaloriePoint(to: timestamp)
              let distancePoint = DatabaseManager.shared.fetchClosestDistancePoint(to: timestamp)

                let calories = caloriePoint?.calories ?? 0.0
                let distance = distancePoint?.distance ?? 0.0
                let steps = workout.stepPoints[safe: i]?.steps ?? 0
                let heartRate = workout.heartRatePoints[safe: i]?.bpm ?? 0
                let temp = workout.coreTempPoints[safe: i]?.temp ?? 0

                csv += "\(iso8601(timestamp)),\(calories),\(distance),\(steps),\(heartRate),\(temp)\n"
            }

            csv += "\nWorkout Summary\n"
            csv += "Metric,Value\n"
            csv += "Total Time,\(durationString(from: workout.startTime, to: workout.endTime))\n"
            csv += "Calories Burned,\(workout.totalCalories)\n"
            csv += "Distance Walked,\(workout.totalDistance)\n"
            csv += "Steps Walked,\(workout.totalSteps)\n"
            csv += "Core Temp (Min),\(workout.coreTempMin)\n"
            csv += "Core Temp (Avg),\(workout.averageCoreTemp ?? 0)\n"
            csv += "Core Temp (Max),\(workout.maxCoreTemp ?? 0)\n"
            csv += "Heart Rate (Min),\(workout.heartRateMin)\n"
            csv += "Heart Rate (Avg),\(workout.averageHeartRate ?? 0)\n"
            csv += "Heart Rate (Max),\(workout.maxHeartRate ?? 0)\n"

            let responses = DatabaseManager.shared.fetchQuestionnaireResponses(for: workout.id)
            let formatter = ISO8601DateFormatter()

            for response in responses {
              if let date = formatter.date(from: response.timestamp) {
                      csv += "\nQuestionnaire @ \(iso8601(date))\n"
                  } else {
                      csv += "\nQuestionnaire @ INVALID_DATE\n"
                  }
                csv += "Exertion,Hydration,Thermal\n"
                csv += "\(response.exertion),\(response.hydration),\(response.thermal)\n"
            }

            csv += "\n\n"
        }

        // MARK: Save CSV
        let filename = "ResearchDataExport_\(UUID().uuidString.prefix(6)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)

        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("✅ CSV file saved at: \(url.path)")

            if FileManager.default.fileExists(atPath: url.path) {
                let size = try FileManager.default.attributesOfItem(atPath: url.path)[.size] as? UInt64 ?? 0
                print("✅ File size: \(size) bytes")
                return url
            } else {
                print("❌ File does not exist after saving.")
            }
        } catch {
            print("❌ Error writing CSV: \(error.localizedDescription)")
        }

        return nil
    }

    private static func iso8601(_ date: Date) -> String {
        let formatter = ISO8601DateFormatter()
        return formatter.string(from: date)
    }

    private static func calculateAge(from dob: Date) -> Int {
        Calendar.current.dateComponents([.year], from: dob, to: Date()).year ?? 0
    }

    private static func durationString(from start: Date, to end: Date) -> String {
        let interval = Int(end.timeIntervalSince(start))
        let hours = interval / 3600
        let minutes = (interval % 3600) / 60
        let seconds = interval % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - Safe array indexing
extension Array {
    subscript(safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

