import Foundation
import HealthKit
import Combine

class WorkoutManager: NSObject, ObservableObject {

    private let healthStore = HKHealthStore()

    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?

    @Published var workoutStartDate: Date?
    @Published var elapsedTime: TimeInterval = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0

    private var timerCancellable: AnyCancellable?

    // MARK: - Start Workout

    func startWorkout() {
        let config = HKWorkoutConfiguration()
        config.activityType = .walking
        config.locationType = .indoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()

            session?.delegate = self
            builder?.delegate = self
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                          workoutConfiguration: config)

            workoutStartDate = Date()
            session?.startActivity(with: workoutStartDate!)
            builder?.beginCollection(withStart: workoutStartDate!) { success, error in
                // You can handle errors here if needed
            }

            startTimer()

        } catch {
            print("Failed to start workout: \(error)")
        }
    }

    func endWorkout() {
        session?.end()
        builder?.endCollection(withEnd: Date()) { success, error in
            self.builder?.finishWorkout { workout, error in
                // Workout finished
            }
        }

        timerCancellable?.cancel()
    }

    func pauseWorkout() {
        session?.pause()
        timerCancellable?.cancel()
    }

    func resumeWorkout() {
        session?.resume()
        startTimer()
    }

    // MARK: - Timer

    private func startTimer() {
        timerCancellable = Timer
            .publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let start = self?.workoutStartDate else { return }
                self?.elapsedTime = Date().timeIntervalSince(start)
            }
    }
}

// MARK: - HKWorkoutSessionDelegate
extension WorkoutManager: HKWorkoutSessionDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState, date: Date) {
        // Optionally handle state changes
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error)")
    }
}

// MARK: - HKLiveWorkoutBuilderDelegate
extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        // Handle workout events if needed
    }

    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                        didCollectDataOf collectedTypes: Set<HKSampleType>) {

        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType,
                  let statistics = builder?.statistics(for: quantityType) else { continue }

            switch quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                heartRate = statistics.mostRecentQuantity()?
                    .doubleValue(for: .count().unitDivided(by: .minute())) ?? 0

            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                activeEnergy = statistics.sumQuantity()?
                    .doubleValue(for: .kilocalorie()) ?? 0

            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning):
                let meters = statistics.sumQuantity()?.doubleValue(for: .meter()) ?? 0
                distance = meters / 1000  // Convert to km

            default:
                break
            }
        }
    }
}

