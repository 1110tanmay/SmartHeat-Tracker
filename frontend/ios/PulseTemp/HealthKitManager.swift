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
}

