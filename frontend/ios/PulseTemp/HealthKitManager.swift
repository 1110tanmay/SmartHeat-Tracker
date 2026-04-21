import Foundation
import HealthKit
import Combine
import WatchConnectivity
import UIKit

class HealthKitManager: NSObject, ObservableObject, HKWorkoutSessionDelegate {
  static let shared = HealthKitManager()
  let healthStore = HKHealthStore()
  
  @Published var latestHeartRate: Double? = nil
  @Published var latestSteps: Int? = nil
  @Published var latestCalories: Double? = nil
  @Published var latestDistance: Double? = nil
  @Published var latestCoreTemp: Double? = nil
  
  @Published var heartRateData: [HeartRatePoint] = []
  @Published var stepsTrendData: [StepPoint] = []
  @Published var caloriesTrendData: [CaloriePoint] = []
  @Published var distanceTrendData: [DistancePoint] = []
  @Published var coreTempTrendData: [CoreTempPoint] = []
  
  @Published var historicalHeartRate: [HeartRatePoint] = []
  @Published var historicalSteps: [StepPoint] = []
  @Published var historicalCalories: [CaloriePoint] = []
  @Published var historicalDistance: [DistancePoint] = []
  @Published var historicalCoreTemp: [CoreTempPoint] = []
  private let ecTempCalculator = ECTempCalculator()
  private var mirroredSession: HKWorkoutSession?
  private override init() {
    super.init()
    setupWorkoutSessionMirroring()
  }
  
  private func setupWorkoutSessionMirroring() {
    healthStore.workoutSessionMirroringStartHandler = { [weak self] mirroredSession in
      print("📱 IPHONE LOG: Mirrored session received from Apple Watch!")
      self?.mirroredSession = mirroredSession
      self?.mirroredSession?.delegate = self
    }
  }
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
  
  func fetchAllMetricsForInitialSync() {
    fetchLatestHeartRateAndUpdateCoreTemp()
    fetchHistoricalSteps()
    fetchHistoricalCalories()
    fetchHistoricalDistance()
  }
  
  func setupBackgroundHeartRateObserver() {
    guard let sampleType = HKObjectType.quantityType(forIdentifier: .heartRate) else {
      print("🛑 Failed to get heart rate sample type for observer.")
      return
    }
    
    let observerQuery = HKObserverQuery(sampleType: sampleType, predicate: nil) { [weak self] _, completionHandler, error in
      if let error = error {
        print("🛑 HKObserverQuery error: \(error.localizedDescription)")
        completionHandler()
        return
      }
      print("❤️ HKObserverQuery fired. Triggering data processing.")
      self?.fetchLatestHeartRateAndUpdateCoreTemp()
      completionHandler()
    }
    
    healthStore.execute(observerQuery)
    
    healthStore.enableBackgroundDelivery(for: sampleType, frequency: .immediate) { success, error in
      if success {
        print("✅ Background delivery enabled for HR observer.")
      } else {
        if let error = error {
          print("🛑 Failed to enable background delivery: \(error.localizedDescription)")
        }
      }
    }
  }
  
  func fetchLatestHeartRateAndUpdateCoreTemp() {
    guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else {
      return
    }
    
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    
    let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { [weak self] _, results, _ in
      guard let self = self, let sample = results?.first as? HKQuantitySample else {
        print("⚠️ ObserverQuery triggered but no new heart rate sample found")
        return
      }
      
      let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
      let timestamp = sample.startDate
      let temp = self.ecTempCalculator.updateCoreTemp(with: bpm)
      
      DispatchQueue.main.async {
        self.latestHeartRate = bpm
        self.latestCoreTemp = temp
        
        // ✅ Store to database as usual
        DatabaseManager.shared.insertHeartRatePoint(HeartRatePoint(timestamp: timestamp, bpm: bpm))
        DatabaseManager.shared.insertCoreTempPoint(CoreTempPoint(timestamp: timestamp, temp: temp))
        
        // ✅ Send data via Mirrored Session (NOT WatchConnectivity)
        //   let workoutData: [String: Any] = ["heartRate": bpm, "coreTemp": temp]
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
        
        if let latestDistance = self.latestDistance {
          DatabaseManager.shared.insertDistancePoint(DistancePoint(timestamp: Date(), distance: latestDistance))
        }
      }
    }
    healthStore.execute(query)
  }
  
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
  func fetchCoreTempTrend() {
    let startDate = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
    let allTrendData = DatabaseManager.shared.fetchAllCoreTempPoints()
    let filteredData = allTrendData.filter { $0.timestamp >= startDate }
    DispatchQueue.main.async {
      self.coreTempTrendData = filteredData
      print("📈 Core Temp Trend Data loaded with \(filteredData.count) points.")
    }
  }
  func fetchAllMetrics() {
    fetchLatestHeartRateAndUpdateCoreTemp()
    fetchLatestSteps()
    fetchLatestCalories()
    fetchLatestDistance()
    fetchHeartRateTrend()
    fetchCaloriesTrend()
    fetchStepsTrend()
    fetchDistanceTrend()
    syncHistoricalHeartRateAndCoreTemp()
    syncHistoricalSteps()
    syncHistoricalCalories()
    syncHistoricalDistance()
  }
  
  // MARK: - Fetch Long-Term Historical Metrics (for TrendsView)
  // ... no changes here ...
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
  
  func syncHistoricalHeartRateAndCoreTemp() {
    guard let type = HKQuantityType.quantityType(forIdentifier: .heartRate) else { return }
    let now = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now)
    let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
    let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sort]) { _, results, error in
      if let error = error {
        print("Failed to fetch historical heart rate samples: \(error)")
        return
      }
      let samples = results as? [HKQuantitySample] ?? []
      DispatchQueue.global(qos: .background).async {
        for sample in samples {
          let bpm = sample.quantity.doubleValue(for: .count().unitDivided(by: .minute()))
          let timestamp = sample.startDate
          
          let heartRatePoint = HeartRatePoint(timestamp: timestamp, bpm: bpm)
          DatabaseManager.shared.insertHeartRatePoint(heartRatePoint)
          
          let calculatedCoreTemp = self.ecTempCalculator.updateCoreTemp(with: bpm)
          let coreTempPoint = CoreTempPoint(timestamp: timestamp, temp: calculatedCoreTemp)
          DatabaseManager.shared.insertCoreTempPoint(coreTempPoint)
        }
        print("✅ Historical Heart Rate and Core Temp sync completed: \(samples.count) samples.")
      }
    }
    
    healthStore.execute(query)
  }
  
  func syncHistoricalSteps() {
    guard let type = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
    
    let now = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    
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
  
  func syncHistoricalCalories() {
    guard let type = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned) else { return }
    
    let now = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    
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
  
  func syncHistoricalDistance() {
    guard let type = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning) else { return }
    
    let now = Date()
    let startDate = Calendar.current.date(byAdding: .day, value: -30, to: now)!
    
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
  func workoutSession(_ workoutSession: HKWorkoutSession, didReceiveDataFromRemoteDevice data: Data) {
    print("📱 IPHONE LOG: Received data prompt from watch via mirrored session. Triggering processing.")
    fetchLatestHeartRateAndUpdateCoreTemp()
  }
  func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
    print("ℹ️ iPhone workout session state changed from \(fromState.rawValue) to \(toState.rawValue)")
  }
  
  func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
    print("🛑 iPhone mirrored workout session failed: \(error.localizedDescription)")
  }
}
