import Foundation
import HealthKit
import Combine
import WatchConnectivity

class HealthKitManager: ObservableObject {
    static let shared = HealthKitManager()
    let healthStore = HKHealthStore()

    // MARK: - Published Properties for Live Metrics
    @Published var latestHeartRate: Double? = nil
    @Published var latestSteps: Int? = nil
    @Published var latestCalories: Double? = nil
    @Published var latestDistance: Double? = nil
    @Published var latestCoreTemp: Double? = nil

    // MARK: - Published Trend Data
    @Published var heartRateData: [HeartRatePoint] = []
    @Published var stepsTrendData: [StepPoint] = []
    @Published var caloriesTrendData: [CaloriePoint] = []
    @Published var distanceTrendData: [DistancePoint] = []
    @Published var coreTempTrendData: [CoreTempPoint] = []

    // MARK: - Historical Data (for TrendsView)
    @Published var historicalHeartRate: [HeartRatePoint] = []
    @Published var historicalSteps: [StepPoint] = []
    @Published var historicalCalories: [CaloriePoint] = []
    @Published var historicalDistance: [DistancePoint] = []
    @Published var historicalCoreTemp: [CoreTempPoint] = []

    private let ecTempCalculator = ECTempCalculator()
    private var liveSyncTimer: Timer?

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
          DispatchQueue.main.async {
              if success {
                  print("✅ HealthKit authorization successful")
                  self.enableBackgroundHeartRateDelivery()
                  self.setupBackgroundHeartRateObserver()
              }
              completion(success, error)
          }
      }
    }
  func enableBackgroundHeartRateDelivery() {
      guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

      healthStore.enableBackgroundDelivery(for: heartRateType, frequency: .immediate) { success, error in
          if success {
              print("✅ Background delivery enabled for heart rate")
          } else {
              print("🛑 Failed to enable background delivery: \(error?.localizedDescription ?? "unknown error")")
          }
      }
  }
  func setupBackgroundHeartRateObserver() {
      guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
          print("🛑 Failed to get heart rate sample type")
          return
      }

      print("📣 Registering HKObserverQuery for heart rate")

      let observerQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, _, error in
          if let error = error {
              print("🛑 ObserverQuery error: \(error.localizedDescription)")
              return
          }

          print("🔁 Background heart rate update received at \(Date())")

          // Trigger your normal fetch + sync process
          self?.fetchLatestHeartRate()
      }

      healthStore.execute(observerQuery)

      // Always enable background delivery when registering an observer
      healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
          if success {
              print("✅ Background delivery enabled for HR")
          } else {
              print("🛑 Failed to enable BG delivery: \(error?.localizedDescription ?? "Unknown error")")
          }
      }
  }


  private func sendLiveMetricsToWatch(hr: Double, temp: Double) {
      guard WCSession.default.isReachable else {
          print("📡 Watch not reachable")
          return
      }

      let message: [String: Any] = [
          "heartRate": hr,
          "coreTemp": temp
      ]

      WCSession.default.sendMessage(message, replyHandler: nil) { error in
          print("🛑 Failed to send to Watch: \(error.localizedDescription)")
      }
  }

  
  func fetchLatestHeartRate() {
      guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
      let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
      
      let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, results, _ in
          guard let sample = results?.first as? HKQuantitySample else { return }
          let unit = HKUnit.count().unitDivided(by: .minute())
          
          DispatchQueue.main.async {
              let heartRate = sample.quantity.doubleValue(for: unit)
              self.latestHeartRate = heartRate
              self.heartRateData.append(HeartRatePoint(timestamp: Date(), bpm: heartRate))
              if self.heartRateData.count > 100 { self.heartRateData.removeFirst() }

              // ➡️ Insert into database
              DatabaseManager.shared.insertHeartRatePoint(HeartRatePoint(timestamp: Date(), bpm: heartRate))

              let ct = self.ecTempCalculator.updateCoreTemp(with: heartRate)
              self.latestCoreTemp = ct
              self.coreTempTrendData.append(CoreTempPoint(timestamp: Date(), temp: ct))
              if self.coreTempTrendData.count > 60 { self.coreTempTrendData.removeFirst() }

              // ✅ Add this line at the end of the DispatchQueue block:
              self.sendLiveMetricsToWatch(hr: heartRate, temp: ct)
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
                
                // ➡️ Insert into database
                if let latestSteps = self.latestSteps {
                    DatabaseManager.shared.insertStepPoint(StepPoint(timestamp: Date(), steps: latestSteps))
                }
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

                // ➡️ Insert into database
                if let latestCalories = self.latestCalories {
                    DatabaseManager.shared.insertCaloriePoint(CaloriePoint(timestamp: Date(), calories: latestCalories))
                }
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
                self.latestDistance = sum.doubleValue(for: .meter()) / 1000.0

                // ➡️ Insert into database
                if let latestDistance = self.latestDistance {
                    DatabaseManager.shared.insertDistancePoint(DistancePoint(timestamp: Date(), distance: latestDistance))
                }
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Fetch Short-Term Trends (6 hours)
    func fetchHeartRateTrend() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
        let start = Calendar.current.date(byAdding: .minute, value: -30, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, results, _ in
            DispatchQueue.main.async {
                self.heartRateData = (results as? [HKQuantitySample] ?? []).map { sample in
                    let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                    return HeartRatePoint(timestamp: sample.startDate, bpm: bpm)
                }
            }
        }
        healthStore.execute(query)
    }

    func fetchCaloriesTrend() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
        let start = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, results, _ in
            var data: [CaloriePoint] = []
            for sample in results as? [HKQuantitySample] ?? [] {
                let kcal = sample.quantity.doubleValue(for: .kilocalorie())
                data.append(CaloriePoint(timestamp: sample.startDate, calories: kcal))
            }
            DispatchQueue.main.async {
                self.caloriesTrendData = data
            }
        }
        healthStore.execute(query)
    }

    func fetchStepsTrend() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        let start = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, results, _ in
            var data: [StepPoint] = []
            for sample in results as? [HKQuantitySample] ?? [] {
                let steps = Int(sample.quantity.doubleValue(for: .count()))
                data.append(StepPoint(timestamp: sample.startDate, steps: steps))
            }
            DispatchQueue.main.async {
                self.stepsTrendData = data
            }
        }
        healthStore.execute(query)
    }

    func fetchDistanceTrend() {
        guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
        let start = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 100, sortDescriptors: [sort]) { _, results, _ in
            var data: [DistancePoint] = []
            for sample in results as? [HKQuantitySample] ?? [] {
                let meters = sample.quantity.doubleValue(for: .meter())
                data.append(DistancePoint(timestamp: sample.startDate, distance: meters / 1000.0))
            }
            DispatchQueue.main.async {
                self.distanceTrendData = data
            }
        }
        healthStore.execute(query)
    }

    // MARK: - Fetch All Metrics (SummaryView)
    func fetchAllMetrics() {
        fetchLatestHeartRate()
        fetchLatestSteps()
        fetchLatestCalories()
        fetchLatestDistance()
        fetchHeartRateTrend()
        fetchCaloriesTrend()
        fetchStepsTrend()
        fetchDistanceTrend()
      // 🔥 Historical Syncs
         syncHistoricalHeartRateAndCoreTemp()
         syncHistoricalSteps()
      syncHistoricalCalories()
      syncHistoricalDistance()
    }

    // MARK: - Fetch Long-Term Historical Metrics (for TrendsView)
    func fetchHistoricalHeartRate() {
        self.historicalHeartRate = DatabaseManager.shared.fetchAllHeartRatePoints()
    }

    func fetchHistoricalSteps() {
        self.historicalSteps = DatabaseManager.shared.fetchAllStepPoints()
    }

    func fetchHistoricalCalories() {
        self.historicalCalories = DatabaseManager.shared.fetchAllCaloriePoints()
    }

    func fetchHistoricalDistance() {
        self.historicalDistance = DatabaseManager.shared.fetchAllDistancePoints()
    }

    func fetchHistoricalCoreTemp() {
        self.historicalCoreTemp = DatabaseManager.shared.fetchAllCoreTempPoints()
    }
  // MARK: - Historical Sync for Heart Rate and Core Temp

  func syncHistoricalHeartRateAndCoreTemp() {
      guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }

      let now = Date()
      let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!

      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
      let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

      let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
          if let error = error {
              print("Failed to fetch historical heart rate samples: \(error)")
              return
          }

          let samples = results as? [HKQuantitySample] ?? []

          // Process in background to avoid blocking UI
          DispatchQueue.global(qos: .background).async {
              for sample in samples {
                  let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
                  let timestamp = sample.startDate

                  // Save Heart Rate Point
                  let heartRatePoint = HeartRatePoint(timestamp: timestamp, bpm: bpm)
                  DatabaseManager.shared.insertHeartRatePoint(heartRatePoint)

                  // Calculate and Save Core Temp Point
                  let calculatedCoreTemp = self.ecTempCalculator.updateCoreTemp(with: bpm)
                  let coreTempPoint = CoreTempPoint(timestamp: timestamp, temp: calculatedCoreTemp)
                  DatabaseManager.shared.insertCoreTempPoint(coreTempPoint)
              }
              print("✅ Historical Heart Rate and Core Temp sync completed: \(samples.count) samples.")
          }
      }

      healthStore.execute(query)
  }
  // MARK: - Historical Sync for Steps

  func syncHistoricalSteps() {
      guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }

      let now = Date()
      let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!

      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
      let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

      let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
          if let error = error {
              print("Failed to fetch historical step samples: \(error)")
              return
          }

          let samples = results as? [HKQuantitySample] ?? []

          DispatchQueue.global(qos: .background).async {
              for sample in samples {
                  let steps = Int(sample.quantity.doubleValue(for: .count()))
                  let timestamp = sample.startDate

                  let stepPoint = StepPoint(timestamp: timestamp, steps: steps)
                  DatabaseManager.shared.insertStepPoint(stepPoint)
              }
              print("✅ Historical Steps sync completed: \(samples.count) samples.")
          }
      }

      healthStore.execute(query)
  }

  // MARK: - Historical Sync for Calories Burned

  func syncHistoricalCalories() {
      guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }

      let now = Date()
      let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!

      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
      let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

      let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
          if let error = error {
              print("Failed to fetch historical calorie samples: \(error)")
              return
          }

          let samples = results as? [HKQuantitySample] ?? []

          DispatchQueue.global(qos: .background).async {
              for sample in samples {
                  let calories = sample.quantity.doubleValue(for: .kilocalorie())
                  let timestamp = sample.startDate

                  let caloriePoint = CaloriePoint(timestamp: timestamp, calories: calories)
                  DatabaseManager.shared.insertCaloriePoint(caloriePoint)
              }
              print("✅ Historical Calories sync completed: \(samples.count) samples.")
          }
      }

      healthStore.execute(query)
  }
  // MARK: - Historical Sync for Distance Covered

  func syncHistoricalDistance() {
      guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }

      let now = Date()
      let startDate = Calendar.current.date(byAdding: .day, value: -1, to: now)!

      let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
      let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

      let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
          if let error = error {
              print("Failed to fetch historical distance samples: \(error)")
              return
          }

          let samples = results as? [HKQuantitySample] ?? []

          DispatchQueue.global(qos: .background).async {
              for sample in samples {
                  let distanceKm = sample.quantity.doubleValue(for: .meter()) / 1000.0
                  let timestamp = sample.startDate

                  let distancePoint = DistancePoint(timestamp: timestamp, distance: distanceKm)
                  DatabaseManager.shared.insertDistancePoint(distancePoint)
              }
              print("✅ Historical Distance sync completed: \(samples.count) samples.")
          }
      }

      healthStore.execute(query)
  }

  func startLiveSync() {
      // Invalidate existing timer if any
      liveSyncTimer?.invalidate()

      // Start new timer
      liveSyncTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: true) { [weak self] _ in
          self?.fetchLatestHeartRate()
      }

      print("⏱️ Live iPhone → Watch sync started")
  }

  func stopLiveSync() {
      liveSyncTimer?.invalidate()
      liveSyncTimer = nil
      print("⛔️ Live sync stopped")
  }

}

