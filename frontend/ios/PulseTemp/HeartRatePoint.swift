import Foundation
import HealthKit
import Combine

// MARK: - Heart Rate Data Point Struct
struct HeartRatePoint: Identifiable {
    let id = UUID()
    let timestamp: String
    let bpm: Int
}

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

        let start = Calendar.current.date(byAdding: .hour, value: -6, to: Date()) ?? Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: Date())
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)

        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 50, sortDescriptors: [sort]) { _, results, _ in
            var data: [HeartRatePoint] = []

            for sample in results as? [HKQuantitySample] ?? [] {
                let bpm = Int(sample.quantity.doubleValue(for: .count().unitDivided(by: .minute())))
                let time = Self.timeFormatter.string(from: sample.startDate)
                data.append(HeartRatePoint(timestamp: time, bpm: bpm))
            }

            DispatchQueue.main.async {
                self.heartRateData = data
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Stub Trend Fetchers (Temporary Mock Data)
    func fetchStepsTrend() {
        stepsTrendData = [
            StepPoint(timestamp: "9 AM", steps: 1000),
            StepPoint(timestamp: "10 AM", steps: 1400),
            StepPoint(timestamp: "11 AM", steps: 1800),
            StepPoint(timestamp: "12 PM", steps: 2000)
        ]
    }

    func fetchCaloriesTrend() {
        caloriesTrendData = [
            CaloriePoint(timestamp: "9 AM", calories: 90),
            CaloriePoint(timestamp: "10 AM", calories: 120),
            CaloriePoint(timestamp: "11 AM", calories: 150),
            CaloriePoint(timestamp: "12 PM", calories: 180)
        ]
    }

    func fetchDistanceTrend() {
        distanceTrendData = [
            DistancePoint(timestamp: "9 AM", distance: 0.6),
            DistancePoint(timestamp: "10 AM", distance: 1.2),
            DistancePoint(timestamp: "11 AM", distance: 2.0),
            DistancePoint(timestamp: "12 PM", distance: 2.8)
        ]
    }

    // MARK: - Fetch All At Once (used in SummaryView)
    func fetchAllMetrics() {
        fetchLatestHeartRate()
        fetchLatestSteps()
        fetchLatestCalories()
        fetchLatestDistance()
        fetchHeartRateTrend()
    }

    // MARK: - Formatter for Timestamps
    private static var timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }()
}

