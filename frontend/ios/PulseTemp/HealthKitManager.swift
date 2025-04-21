import Foundation
import HealthKit
import Combine

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    // MARK: - Published Properties for Live Metrics
    @Published var latestHeartRate: Double? = nil
    @Published var latestSteps: Int? = nil
    @Published var latestCalories: Double? = nil
    @Published var latestDistance: Double? = nil

    // MARK: - Published Trend Data
    @Published var heartRateData: [HeartRatePoint] = []
    @Published var stepsTrendData: [StepPoint] = []
    @Published var caloriesTrendData: [CaloriePoint] = []
    @Published var distanceTrendData: [DistancePoint] = []

    private init() {}

    // MARK: - Authorization
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(false, nil)
            return
        }

        let readTypes: Set = [
            HKObjectType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!,
            HKObjectType.quantityType(forIdentifier: .stepCount)!,
            HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)!
        ]

        healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, error in
            completion(success, error)
        }
    }

    // MARK: - Fetch Latest Values
    func fetchLatestHeartRate() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, results, _ in
            guard let sample = results?.first as? HKQuantitySample else { return }
            let unit = HKUnit.count().unitDivided(by: .minute())
            DispatchQueue.main.async {
                self.latestHeartRate = sample.quantity.doubleValue(for: unit)
            }
        }
        healthStore.execute(query)
    }

    func fetchLatestSteps() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.latestSteps = Int(sum.doubleValue(for: .count()))
            }
        }
        healthStore.execute(query)
    }

    func fetchLatestCalories() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.latestCalories = sum.doubleValue(for: .kilocalorie())
            }
        }
        healthStore.execute(query)
    }

    func fetchLatestDistance() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        let now = Date()
        let start = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: now)
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, _ in
            guard let sum = result?.sumQuantity() else { return }
            DispatchQueue.main.async {
                self.latestDistance = sum.doubleValue(for: .meter()) / 1000.0 // Store in km
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Fetch Heart Rate Trend (Chart Data)
  func fetchHeartRateTrend() {
      guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

      let start = Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date()
      let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
      let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

      let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, results, _ in
          DispatchQueue.main.async {
              for sample in results as? [HKQuantitySample] ?? [] {
                  let bpm = Int(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())))
                  let timestamp = sample.startDate
                  let point = HeartRatePoint(timestamp: timestamp, bpm: bpm)

                  // ✅ Append only if it's newer than the last timestamp
                  if let last = self.heartRateData.last {
                      if point.timestamp > last.timestamp {
                          self.heartRateData.append(point)
                      }
                  } else {
                      // If list is empty, add first point
                      self.heartRateData.append(point)
                  }

                  // ✅ Optional: keep list size under 100
                  if self.heartRateData.count > 100 {
                      self.heartRateData.removeFirst()
                  }
              }
          }
      }

      healthStore.execute(query)
  }



  private func timeStringToDate(_ time: String) -> Date {
      let formatter = DateFormatter()
      formatter.dateFormat = "h a"
      formatter.locale = Locale(identifier: "en_US_POSIX")
      return formatter.date(from: time) ?? Date()
  }

    // MARK: - Fetch Calories Trend
    func fetchCaloriesTrend() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

        let start = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, results, _ in
            var data: [CaloriePoint] = []

            for sample in results as? [HKQuantitySample] ?? [] {
                let kcal = sample.quantity.doubleValue(for: .kilocalorie())
                let time = Self.timeFormatter.string(from: sample.startDate)
              data.append(CaloriePoint(date: sample.startDate, calories: kcal))
            }

            DispatchQueue.main.async {
                self.caloriesTrendData = data
            }
        }

        healthStore.execute(query)
    }


    // MARK: - Fetch All At Once (used in SummaryView)
    func fetchAllMetrics() {
        fetchLatestHeartRate()
        fetchLatestSteps()
        fetchLatestCalories()
        fetchLatestDistance()
        fetchHeartRateTrend()
        fetchCaloriesTrend()
    }

    // MARK: - Formatter for Timestamps
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

